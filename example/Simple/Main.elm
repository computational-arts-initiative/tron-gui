module Simple.Main exposing (view, update)


import Browser
import Color
import Json.Decode as Decode
import Json.Encode as Encode
import Html
import Html exposing (Html)
import Html.Attributes as Html

import Gui.Build as Gui
import Gui.Gui exposing (Gui)

import Simple.Gui as Simple
import Simple.Model exposing (..)
import Simple.Model as Model exposing (init)
import Simple.Msg exposing (..)


update : Msg -> Model -> Model
update msg model =
    case msg of
        NoOp -> model
        ChangeInt int -> { model | int = int }
        ChangeFloat float -> { model | float = float }
        ChangeString string -> { model | string = string }
        ChangeColor color -> { model | color = color }
        ChangeXY xy -> { model | xy = xy }
        Choose choice -> { model | choice = choice }
        Switch to -> { model | toggle = to }
        Pressed choice -> { model | buttonPressed = choice }


view : Model -> Html Msg
view model =
    Html.ul
        []
        [ Html.li [] [ Html.text <| String.fromInt model.int ]
        , Html.li [] [ Html.text <| String.fromFloat model.float ]
        , Html.li [] [ Html.text <|
                ( String.fromFloat <| Tuple.first model.xy ) ++ ":" ++
                ( String.fromFloat <| Tuple.second model.xy )
            ]
        , Html.li [] [ Html.text <| model.string ]
        , Html.li [] [ Html.text <| choiceToString model.choice ]
        , Html.li
            [ Html.style "background-color" <| Color.toCssString model.color ]
            [ Html.text <| Color.toCssString model.color ]
        , Html.li [] [ Html.text <| if model.toggle then "On" else "Off" ]
        , Html.li [] [ Html.text <| choiceToString model.buttonPressed ]
        ]




