module Gui.Nest exposing (..)


import Array

import Gui.Def exposing (..)


-- map : (umsg1 -> umsg2) -> Nest umsg1 -> Nest umsg2
-- map = -- TODO


noChildren : Nest umsg
noChildren =
    { focus = -1
    , shape = ( 0, 0 )
    , cells = []
    }


oneLine : Cells umsg -> Nest umsg
oneLine cells =
    { focus = -1
    , shape = ( List.length cells, 1 )
    , cells = cells
    }


nestWithin : Shape -> Cells umsg -> Nest umsg
nestWithin shape cells =
    { focus = -1
    , shape = shape
    , cells = cells
    }


traverseNest : (Cell umsg -> NestPos -> Cell umsg) -> Nest umsg -> Nest umsg
traverseNest f nest =
    { nest
    | cells = nest.cells |> traverseCells f
    }


traverseCells : (Cell umsg -> NestPos -> Cell umsg) -> Cells umsg -> Cells umsg
traverseCells f cells =
    let
        scanCell maybeParentPos index cell =
            let
                nestPos =
                    case maybeParentPos of
                        Just parentPos -> parentPos |> deeper index
                        Nothing -> root index
            in case f cell nestPos of
                Nested label state nest ->
                    Nested
                        label
                        state
                        { nest
                        | cells =
                            nest.cells
                                |> List.indexedMap (scanCell (Just nestPos))
                        }
                Choice label state selected handler nest ->
                    Choice
                        label
                        state
                        selected
                        handler
                        { nest
                        | cells =
                            nest.cells |>
                                List.indexedMap (scanCell (Just nestPos))
                        }
                newCell -> newCell

    in
        List.indexedMap (scanCell Nothing) cells


traverseAllNests : (Nest umsg -> NestPos -> Nest umsg) -> Nest umsg -> Nest umsg
traverseAllNests f nest =
    f nest nowhere |>
        (\modNest ->
            { modNest
            | cells = f nest nowhere |> .cells |> traverseCells
                (\cell cellPosition ->
                    case cell of
                        Nested label state innerNest ->
                            f innerNest cellPosition
                                |> Nested label state
                        Choice label state selected handler innerNest ->
                            f innerNest cellPosition
                                |> Choice label state selected handler
                        _ -> cell
                )
            }
        )


foldCells : (Cell umsg -> NestPos -> a -> a) -> a -> Nest umsg -> a
foldCells = foldCells_ Nothing


foldCells_ : Maybe NestPos -> (Cell umsg -> NestPos -> a -> a) -> a -> Nest umsg -> a
foldCells_ maybeParentPos f default { cells } =
    let
        foldingF cell ( index, v ) =
            ( index + 1
            ,   let
                    nestPos =
                        case maybeParentPos of
                            Just parentPos -> parentPos |> deeper index
                            Nothing -> root index
                in case cell of
                    Nested _ _ nest ->
                        foldCells_ (Just nestPos) f (f cell nestPos v) nest
                        -- f cell nestPos <| foldCells_ (Just nestPos) f v nest
                    Choice _ _ _ _ nest ->
                        foldCells_ (Just nestPos) f (f cell nestPos v) nest
                        -- f cell nestPos <| foldCells_ (Just nestPos) f v nest
                    _ -> f cell nestPos v
            )
    in
        List.foldl foldingF (0, default) cells
            |> Tuple.second


foldNests : (Nest umsg -> NestPos -> a -> a) -> a -> Nest umsg -> a
foldNests f default nest =
    nest |>
        foldCells (\cell nestPos v ->
            case cell of
                Nested _ _ innerNest ->
                    f innerNest nestPos v
                Choice _ _ _ _ innerNest ->
                    f innerNest nestPos v
                _ -> v
        ) (f nest nowhere default)


nowhere : NestPos
nowhere = NestPos []


root : Int -> NestPos
root index =
    NestPos [ index ]


deeper : Int -> NestPos -> NestPos
deeper index (NestPos path) =
    NestPos (index :: path)


deeperOrRoot : Int -> Maybe NestPos -> NestPos
deeperOrRoot index maybePos =
    maybePos
        |> Maybe.map (deeper index)
        |> Maybe.withDefault (root index)


shallower : NestPos -> NestPos
shallower (NestPos path) =
    List.tail path
        |> Maybe.withDefault []
        |> NestPos


getNestLevel : NestPos -> Int
getNestLevel (NestPos path) =
    List.length path


getIndexOf : NestPos -> Maybe Int
getIndexOf (NestPos path) =
    List.head path


getParentPos : NestPos -> Maybe NestPos
getParentPos (NestPos path) =
    List.tail path
        |> Maybe.andThen
            (\parentPath ->
                case parentPath of
                    [] -> Nothing
                    _ -> Just parentPath
            )
        |> Maybe.map NestPos


isSamePos : NestPos -> NestPos -> Bool
isSamePos (NestPos lPath) (NestPos rPath) = lPath == rPath


findCell : NestPos -> Nest umsg -> Maybe (Cell umsg)
findCell pos nest =
    nest |>
        foldCells (\cell cellPos maybeFound ->
            case maybeFound of
                Just foundCell -> Just foundCell
                Nothing ->
                    if isSamePos cellPos pos
                        then Just cell
                        else Nothing
        ) Nothing


updateCell : NestPos -> (Cell umsg -> Cell umsg) -> Nest umsg -> Nest umsg
updateCell expectedPos f nest =
    traverseNest
        (\cell nestPos ->
            if isSamePos nestPos expectedPos then
                f cell
            else cell)
        nest


collapseAllAbove : NestPos -> Nest umsg -> Nest umsg
collapseAllAbove position nest =
    nest |> traverseNest
        (\cell cellPosition ->
            if (getNestLevel cellPosition >= getNestLevel position) then
                case cell of
                    Nested label _ nestedCells ->
                        Nested
                            label
                            Collapsed
                            nestedCells
                    Choice label _ selected handler nestedCells ->
                        Choice
                            label
                            Collapsed
                            selected
                            handler
                            nestedCells
                    _ -> cell
            else cell
        )


isDeeper : NestPos -> NestPos -> Bool
isDeeper (NestPos lPath) (NestPos rPath) =
    List.length lPath > List.length rPath


sizeOf : Nest umsg -> Int
sizeOf { cells } =
    List.length cells
