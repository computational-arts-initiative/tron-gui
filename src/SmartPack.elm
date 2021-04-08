module SmartPack exposing
    ( Distribution(..)
    , Bounds
    , SmartPack
    , map, withBounds
    , container
    , pack, carelessPack
    , packAt, carelessPackAt
    , packCloseTo, carelessPackCloseTo
    , resize, dimensions
    , toMatrix, toList
    , fold, get, find
    )


import Array exposing (Array)
import Matrix exposing (Matrix)

import Size exposing (..)

type alias Bounds =
    { x : Int
    , y : Int
    , width : Int
    , height : Int
    }


type Distribution
    = Up
    | Down
    | Right
    | Left


type SmartPack a = SmartPack (Size Cells) (List (Bounds, a))


map : (a -> b) -> SmartPack a -> SmartPack b
map f (SmartPack size list) =
    SmartPack size <| List.map (Tuple.mapSecond f) <| list


withBounds : (Bounds -> Bounds) -> SmartPack a -> SmartPack a
withBounds f (SmartPack size list) =
    SmartPack size <| List.map (Tuple.mapFirst f) <| list


container : Size Cells -> SmartPack a
container size = SmartPack size []


pack : Distribution -> Size Cells -> a -> SmartPack a -> Maybe (SmartPack a)
pack distribution size v sp =
    sp
        |> findSpot distribution size
        |> Maybe.map
            (\pos ->
                sp |> forceAdd pos size v
            )


packAt : ( Int, Int ) -> Size Cells -> a -> SmartPack a -> Maybe (SmartPack a)
packAt pos size v sp =
    if sp |> fitsAt pos size then
        Just <| forceAdd pos size v <| sp
    else Nothing


forceAdd : ( Int, Int ) -> Size Cells -> a -> SmartPack a -> (SmartPack a)
forceAdd (x, y) (Size ( w, h )) v (SmartPack ps xs) =
    SmartPack ps <|
        (
            { x = x
            , y = y
            , width = w
            , height = h
            }
        , v )
        :: xs



packCloseTo
    :  Distribution
    -> ( Int, Int )
    -> Size Cells
    -> a
    -> SmartPack a
    -> Maybe (SmartPack a)
packCloseTo _ _ _ _ s = Just s


carelessPack : Distribution -> Size Cells -> a -> SmartPack a -> SmartPack a
carelessPack distribution size v sp =
    pack distribution size v sp |> Maybe.withDefault sp


carelessPackAt : ( Int, Int ) -> Size Cells -> a -> SmartPack a -> SmartPack a
carelessPackAt pos size v sp =
    packAt pos size v sp |> Maybe.withDefault sp


carelessPackCloseTo
    :  Distribution
    -> ( Int, Int )
    -> Size Cells
    -> a
    -> SmartPack a
    -> SmartPack a
carelessPackCloseTo distribution pos size v sp =
    packCloseTo distribution pos size v sp |> Maybe.withDefault sp


resize : Size Cells -> SmartPack a -> SmartPack a
resize newSize (SmartPack _ items) =
    SmartPack newSize items


toList : SmartPack a -> List (Bounds, a)
toList (SmartPack _ items) = items


dimensions : SmartPack a -> Size Cells
dimensions (SmartPack size _) = size


toMatrix : SmartPack a -> Matrix ( Maybe a )
toMatrix (SmartPack (Size (w, h)) items) =
    let
        fill bounds v matrix =
            List.range bounds.x (bounds.x + bounds.width - 1)
                |> List.map
                    (\x ->
                        List.range bounds.y (bounds.y + bounds.height - 1)
                            |> List.map (Tuple.pair x)
                    )
                |> List.concat
                |> List.foldl (\pos -> Matrix.set pos <| Just v) matrix
    in items
        |> List.sortBy (Tuple.first >> .x)
        |> List.foldl
            (\(bounds, v) ->
                fill bounds v
            )
            (Matrix.initialize (w, h) <| always Nothing)


isEmpty : Maybe a -> Bool
isEmpty cell =
    case cell of
        Just _ -> False
        Nothing -> True


fitsAt : ( Int, Int ) -> Size Cells -> SmartPack a -> Bool
fitsAt (x, y) (Size (cw, ch)) =
    toMatrix
        >> fitsAtM (x, y) (cw, ch)


fitsAtM : ( Int, Int ) -> ( Int, Int ) -> Matrix (Maybe a) -> Bool
fitsAtM (x, y) (cw, ch) =
    Matrix.slice (x, y) (x + cw, y + ch)
        >> foldM (Tuple.second >> isEmpty >> (&&)) True


findSpot : Distribution -> Size Cells -> SmartPack a -> Maybe ( Int, Int )
findSpot distribution size = toMatrix >> findSpotM distribution size


findSpotM : Distribution -> Size Cells -> Matrix (Maybe a) -> Maybe ( Int, Int )
findSpotM distribution (Size (cw, ch)) matrix =
    let
        ( mw, mh ) = Matrix.size matrix
        fitsAt_ (x, y) =
            fitsAtM (x, y) (cw, ch) matrix

        firstPos d =
            case d of
                Down -> (0, 0)
                Right -> (0, 0)
                Left -> (cw - 1, 0)
                Up -> (0, ch - 1)

        maybeNext d (x, y) =
            case d of
                Down -> if y < mh - 1 then Just (x, y + 1) else maybeNext Right (x, 0)
                Up -> if y > 0 then Just (x, y - 1) else maybeNext Right (x, 0)
                Right -> if x < mw - 1 then Just (x + 1, y) else maybeNext Down (0, y)
                Left -> if x > 0 then Just (x - 1, y) else maybeNext Down (0, y)

        helper d (x, y) =
            if fitsAt_ (x, y) then
                Just (x, y)
            else
                maybeNext d (x, y) |> Maybe.andThen (helper d)

    in
        if (cw > 0) && (ch > 0)
            && not (Matrix.isEmpty matrix)
            && (mw >= cw) && (mh >= ch)
            then helper distribution <| firstPos distribution
            else Nothing


find : ( Float, Float ) -> SmartPack a -> Maybe a
find pos = toMatrix >> findM pos


findM : ( Float, Float ) -> Matrix ( Maybe a ) -> Maybe a
findM pos _ = Nothing


fold : (((Int, Int), Maybe a) -> b -> b) -> b -> SmartPack a -> b
fold f init =
    toMatrix >> foldM f init


foldM : (((Int, Int), Maybe a) -> b -> b) -> b -> Matrix (Maybe a) -> b
foldM f init =
    Matrix.toIndexedList
        >> List.foldl f init


get : (Int, Int) -> SmartPack a -> Maybe a
get pos =
    toMatrix
        >> Matrix.get pos
        >> Maybe.andThen identity
