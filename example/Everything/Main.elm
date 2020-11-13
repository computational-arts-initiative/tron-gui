port module Everything.Main exposing (main)


import Browser
import Browser.Events as Browser
import Browser.Dom as Browser
import Browser.Navigation as Navigation
import Json.Decode as Decode
import Json.Decode as D
import Json.Encode as Encode
import Html exposing (Html)
import Html as Html exposing (map, div)
import Html.Attributes as Attr exposing (class)
import Html.Events as Html exposing (onClick)
import Dict exposing (size)
import Task as Task
import Random
import Url exposing (Url)

import Gui exposing (Gui)
import Gui as Gui exposing (view, detachable, subscriptions)
import Gui.Expose as Exp exposing (Update)
import Gui as Tron exposing (Gui)
import Gui.Msg as Tron exposing (Msg(..))
import Gui.Mouse exposing (Position)
import Gui.Build as Tron exposing (Builder)
import Gui.Detach as Detach exposing (fromUrl)
import Gui.Style.Theme exposing (Theme)
import Gui.Style.Theme as Theme
import Gui.Style.Flow exposing (Flow)
import Gui.Style.Flow as Flow

import Default.Main as Default
import Default.Model as Default
import Default.Msg as Default
import Default.Gui as DefaultGui

import RandomGui as Gui exposing (generator)


type Msg
    = NoOp
    | ChangeMode Mode
    | ChangeFlow Flow
    | FromDatGui Exp.RawUpdate
    | ToTron Tron.Msg
    | ToDefault Default.Msg
    | Randomize (Tron.Builder ())
    | SwitchTheme
    | TriggerRandom
    | TriggerDefault


type alias Example
    = Default.Model


type Mode
    = DatGui
    | TronGui


type alias Model =
    { mode : Mode
    , theme : Theme
    , gui : Tron.Gui Msg
    , example : Example
    , url : Url
    }


init : Url -> Navigation.Key -> ( Model, Cmd Msg )
init url _ =
    let
        initialModel = Default.init
        ( gui, startGui ) =
            initialModel
                |> defaultGui url
    in
        (
            { mode = TronGui
            , example = initialModel
            , theme = Theme.light
            , gui = gui
            , url = url
            }
        , startGui
        )


view : Model -> Html Msg
view { mode, gui, example, theme } =
    Html.div
        [ Attr.class <| "example --" ++ Theme.toString theme ]
        [ Html.button
            [ Html.onClick <| ChangeMode TronGui ]
            [ Html.text "Tron" ]
        , Html.button
            [ Html.onClick <| ChangeMode DatGui ]
            [ Html.text "Dat.gui" ]
        , Html.button
            [ Html.onClick TriggerRandom ]
            [ Html.text "Random" ]
        , Html.button
            [ Html.onClick TriggerDefault ]
            [ Html.text "Default" ]
        , Html.button
            [ Html.onClick SwitchTheme ]
            [ Html.text "Theme" ]
        , Html.button
            [ Html.onClick <| ChangeFlow Flow.topToBottom ]
            [ Html.text "Top to Bottom" ]
        , Html.button
            [ Html.onClick <| ChangeFlow Flow.bottomToTop ]
            [ Html.text "Bottom to Top" ]
        , Html.button
            [ Html.onClick <| ChangeFlow Flow.leftToRight ]
            [ Html.text "Left to Right" ]
        , Html.button
            [ Html.onClick <| ChangeFlow Flow.rightToLeft ]
            [ Html.text "Right to Left" ]
        , case mode of
            DatGui -> Html.div [] []
            TronGui ->
                gui
                    |> Gui.view theme
                    |> Html.map ToTron
        , Default.view example
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.mode ) of

        ( ChangeMode DatGui, _ ) ->
            (
                { model
                | mode = DatGui
                }
            , model.gui
                |> Tron.encode
                |> startDatGui
            )

        ( ChangeMode TronGui, _ ) ->
            let
                ( gui, startGui ) =
                    model.example |> defaultGui model.url
            in
                (
                    { model
                    | gui = gui
                    , mode = TronGui
                    }
                , Cmd.batch
                    [ destroyDatGui ()
                    , startGui
                    ]
                )

        ( ToDefault dmsg, _ ) ->
            (
                { model
                | example =
                    Default.update dmsg model.example
                }
            , Cmd.none
            )

        ( ToTron guiMsg, TronGui ) ->
            case model.gui |> Gui.update guiMsg of
                ( nextGui, cmds ) ->
                    (
                        { model
                        | gui = nextGui
                        }
                    , cmds
                    )

        ( ToTron _, DatGui ) -> ( model, Cmd.none )

        ( FromDatGui guiUpdate, DatGui ) ->
            ( model
            , model.gui
                |> Tron.applyRaw guiUpdate
            )

        ( FromDatGui _, TronGui ) -> ( model, Cmd.none )

        ( TriggerRandom, _ ) ->
            ( model
            , Cmd.batch
                [ destroyDatGui ()
                , Gui.generator
                    |> Random.generate Randomize
                ]
            )

        ( Randomize newTree, _ ) ->
            let
                ( newGui, startGui ) =
                    newTree |> Gui.init
            in
                (
                    { model
                    | gui = newGui |> Gui.map (always NoOp)
                    }
                , case model.mode of
                    DatGui ->
                        newGui
                            |> Tron.encode
                            |> startDatGui
                    TronGui ->
                        startGui
                            |> Cmd.map ToTron
                )

        ( TriggerDefault, _ ) ->
            let
                ( gui, startGui ) =
                    Default.init |> defaultGui model.url
            in
                (
                    { model
                    | gui = gui
                    }
                , startGui
                )

        ( SwitchTheme, _ ) ->
            (
                { model
                | theme = Theme.switch model.theme
                }
            , Cmd.none
            )

        ( ChangeFlow newFlow, _ ) ->
            (
                { model
                | gui = model.gui |> Gui.reflow newFlow
                }
            , Cmd.none
            )

        ( NoOp, _ ) -> ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions { mode, gui } =
    case mode of
        DatGui ->
            updateFromDatGui FromDatGui
        TronGui ->
            Gui.subscriptions gui |> Sub.map ToTron


main : Program () Model Msg
main =
    Browser.application
        { init = always init
        , view = \model ->
            { title = "Tron GUI"
            , body = [ view model ]
            }
        , subscriptions = subscriptions
        , update = update
        , onUrlRequest = always NoOp
        , onUrlChange = always NoOp
        }


defaultGui : Url -> Default.Model -> ( Gui Msg, Cmd Msg )
defaultGui url model =
    let
        ( gui, startGui ) =
            DefaultGui.for model
                |> Gui.init
        ( nextGui, launchDetachable )
            = gui
                |> Gui.detachable
                    url
                    ackToWs
                    sendUpdateToWs
                    receieveUpdateFromWs
    in
        ( nextGui
            |> Gui.map ToDefault
        , Cmd.batch
            [ startGui
            , launchDetachable
            ]
            |> Cmd.map ToTron
        )


port startDatGui : Exp.RawProperty -> Cmd msg

port updateFromDatGui : (Exp.RawUpdate -> msg) -> Sub msg

port destroyDatGui : () -> Cmd msg

port ackToWs : Exp.Ack -> Cmd msg

port receieveUpdateFromWs : (Exp.RawUpdate -> msg) -> Sub msg

port sendUpdateToWs : Exp.RawUpdate -> Cmd msg
