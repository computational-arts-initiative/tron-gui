module Tron.Render.Control.Button exposing (..)


import Bounds exposing (BoundsF)
import Color as Color exposing (..)
import Url as Url

import Tron.Path as Path
import Tron.Control exposing (Control(..))
import Tron.Control.Impl.Button as Button

import Tron.Style.Theme as Theme exposing (Theme)
import Tron.Style.Coloring as Coloring exposing (..)
import Tron.Style.Cell as Cell
import Tron.Style.CellShape as CS exposing (CellShape)
import Tron.Style.Selected exposing (Selected(..))

import Tron.Render.Util exposing (State, resetTransform, describeArc, describeMark, arrow)
import Tron.Render.Util as Svg exposing (none)
import Tron.Render.Transform as T
import Tron.Render.Control.Color as Color

import Svg as Svg exposing (Svg)
import Svg.Attributes as SA


-- view : Theme -> State -> BoundsF -> Toggle.Control a -> Svg msg
view : Theme -> State -> Button.Control a -> CellShape -> Path.Label -> BoundsF -> Svg msg
view theme state (Control face _ _) cellShape label bounds =
    viewFace theme state face cellShape label bounds


viewFace : Theme -> State -> Button.Face -> CellShape -> Path.Label -> BoundsF -> Svg msg
viewFace theme ( ( _, _, selected ) as state ) face cellShape label bounds =
    let

        ( cx, cy ) = ( bounds.width / 2, (bounds.height / 2) - 3 )
        ( labelX, labelY ) =
            if CS.isHorizontal cellShape
                then
                    case face of
                        Button.Default -> ( 30, cy + 4 )
                        Button.WithIcon _ -> ( 40, cy )
                        Button.WithColor _ -> ( 40, cy )
                else ( cx, cy )
        textLabel _ =
            Svg.text_
                [ SA.x <| String.fromFloat labelX
                , SA.y <| String.fromFloat labelY
                , SA.class "button__label"
                , SA.fill <| Color.toCssString <| Coloring.text theme state
                , SA.mask <|
                    if not <| CS.isHorizontal cellShape
                        then "url(#button-text-mask)"
                        else "url(#button-text-mask-wide)"
                ]
                [ Svg.text label ]

    in case face of

        Button.Default ->
            if CS.isHorizontal cellShape
                then case selected of
                    Selected ->
                        Svg.g
                            [ resetTransform ]
                            [ Svg.g
                                [ SA.style <|
                                    "transform: "
                                        ++ "translate(" ++ String.fromFloat Cell.gap ++ "px,"
                                                        ++ String.fromFloat (cy - 4) ++ "px)" ]
                                [ arrow (Coloring.text theme state) (T.scale 0.5) (T.rotate 90)
                                ]
                            -- , textLabel ( bounds.width / 2.25 + gap, cy )
                            , textLabel ()
                            ]
                    Usual -> textLabel ()
                else textLabel ()

        Button.WithIcon (Button.Icon icon) ->
            let
                iconUrl =
                    icon theme |> Maybe.map Url.toString |> Maybe.withDefault ""
                    --"./assets/" ++ icon ++ "_" ++ Theme.toString theme ++ ".svg"
                ( iconWidth, iconHeight ) = iconSize cellShape bounds
                ( iconX, iconY ) =
                    if CS.isHorizontal cellShape
                        then
                            ( -20, cy - iconHeight / 2 + 1 )
                        else
                            ( cx - iconWidth / 2, cy - iconHeight / 2 + 1 )
            in
                Svg.g
                    [ resetTransform ]
                    [
                        Svg.image
                        [ SA.xlinkHref <| iconUrl
                        , SA.class "button__icon"
                        , SA.width <| String.fromFloat iconWidth ++ "px"
                        , SA.height <| String.fromFloat iconHeight ++ "px"
                        , SA.x <| String.fromFloat iconX
                        , SA.y <| String.fromFloat iconY
                        ]
                        []
                    , if CS.isHorizontal cellShape
                        then textLabel ()
                        else Svg.none
                    ]

        Button.WithColor theColor ->
            case CS.units cellShape of
                ( CS.Single, CS.Single ) ->
                    Color.viewValue theme state bounds theColor
                ( CS.Twice, _ ) ->
                    Svg.g
                        []
                        [ Color.viewValue
                            theme
                            state
                            { bounds
                            | width = bounds.height
                            }
                            theColor
                        , textLabel ()
                        ]
                _ ->
                    let
                        ( rectWidth, rectHeight ) = ( bounds.width, bounds.height )
                        ( rectX, rectY ) = ( cx - rectWidth / 2, cy - rectHeight / 2 )
                    in
                        Svg.rect
                            [ SA.x <| String.fromFloat rectX
                            , SA.y <| String.fromFloat rectY
                            , SA.width <| String.fromFloat rectWidth
                            , SA.height <| String.fromFloat rectHeight
                            , SA.fill <| Color.toCssString theColor
                            , SA.rx "3"
                            , SA.ry "3"
                            ]
                            [
                            ]

iconSize : CellShape -> BoundsF -> ( Float, Float )
iconSize cs bounds =
    case CS.units cs of
        ( CS.Single, CS.Single ) -> ( 32, 32 )
        _ -> ( bounds.width / 2.25, bounds.height / 2.25 )