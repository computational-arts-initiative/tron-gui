module Constructor.Selector exposing (..)


import Html exposing (Html)
import Html.Attributes as Html
import Html.Events as Html

import Tron.Control.Button as Button
import Tron.Style.CellShape as CS
import Tron.Style.PanelShape as PS

type Selector a = Selector (List a)


icons =
    [ "animation", "blend", "chromatic", "chtomatics", "cursor"
    , "error", "export", "fog", "link", "loaded", "mp4", "png"
    , "save", "settings", "shuffle", "size", "text", "tick", "tile"
    ]


iconSelector : Selector String
iconSelector = Selector icons


iconSource : String -> List String
iconSource icon =
    [ "assets", "tiler", "light-stroke", icon ++ ".svg" ]


viewIconSelector : Maybe Button.Url -> (List String -> msg) -> Html msg
viewIconSelector maybeCurrent onSelect =
    case iconSelector of
        Selector icons_ ->
            Html.div
                [ Html.class "icons"
                ]
                <| List.map
                    (\iconSrc ->
                        Html.img
                            [ Html.src <| String.join "/" iconSrc
                            , Html.onClick <| onSelect iconSrc
                            , Html.class <| case maybeCurrent of
                                Just (Button.Url currentUrl) ->
                                    if String.join "/" iconSrc == currentUrl then "current" else ""
                                Nothing -> ""
                            ]
                            []
                    )
                <| List.map iconSource
                <| icons_


possibleUnits = [ CS.Half, CS.Single, CS.Twice ]


possibleShapes = cartesian possibleUnits possibleUnits


cartesian : List a -> List b -> List (a,b)
cartesian xs ys =
    List.concatMap
        ( \x -> List.map (\y -> (x, y) ) ys )
        xs


unitToStr : CS.Unit -> String
unitToStr unit =
    case unit of
        CS.Single -> "1"
        CS.Half -> "0.5"
        CS.Twice -> "2"


viewCellShapeSelector : CS.CellShape -> (CS.CellShape -> msg) -> Html msg
viewCellShapeSelector current onSelect =
    Html.div
        [ Html.class "cell-shapes"
        ]
        <| List.map
            (\cellShape ->
                Html.div
                    [ Html.onClick <| onSelect cellShape
                    , Html.class
                        <| case ( CS.numify cellShape, CS.numify current ) of
                            ( ( horzA, vertA ), ( horzB, vertB ) ) ->
                                if horzA == horzB && vertA == vertB then "current"
                                else ""
                    ]
                    [ Html.text <|
                        case CS.units cellShape of
                            ( horz, vert ) ->
                                unitToStr horz ++ "x" ++ unitToStr vert
                    ]
            )
        <| List.map CS.create
        <| possibleShapes
