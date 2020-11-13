module Gui.Style.Flow exposing
    ( Flow
    , topToBottom, bottomToTop, leftToRight, rightToLeft
    , adaptBounds, adaptPosition, adaptSize, firstCellAt
    , toString
    )

{-| # Flow
@docs Flow

# Values
@docs topToBottom, bottomToTop, leftToRight, rightToLeft
-}

import Gui.Style.Cell as Cell



{-| Flow describes the direction in which GUI is oriented and to which side it is "docked".

If you are familiar with macOS Dock — here we have the similar concept.
-}
type Flow
    = TopToBottom
    | BottomToTop
    | LeftToRight
    | RightToLeft


{-|
-}
topToBottom : Flow
topToBottom = TopToBottom


{-|
-}
bottomToTop : Flow
bottomToTop = BottomToTop


{-|
-}
leftToRight : Flow
leftToRight = LeftToRight


{-|
-}
rightToLeft : Flow
rightToLeft = RightToLeft


adaptBounds
     : Flow
    -> ( Float, Float )
    -> { x : Float, y : Float, width : Float, height : Float }
    -> { x : Float, y : Float, width : Float, height : Float }
adaptBounds flow ( width, height ) innerBounds =
    case flow of
        TopToBottom -> innerBounds
        BottomToTop ->
            { innerBounds
            | y = height - innerBounds.y - innerBounds.height
            }
        LeftToRight ->
            { width = innerBounds.height
            , height = innerBounds.width
            , x = innerBounds.y
            , y = innerBounds.x
            }
        RightToLeft ->
            { width = innerBounds.height
            , height = innerBounds.width
            , x = height - innerBounds.y - innerBounds.height
            , y = innerBounds.x
            }


adaptPosition : Flow -> ( Float, Float ) -> { x : Float, y : Float } -> { x : Float, y : Float }
adaptPosition flow ( width, height ) { x, y } =
    case flow of
        TopToBottom -> { x = x, y = y }
        BottomToTop ->
            { x = x
            , y = height - y
            }
        LeftToRight ->
            { x = y
            , y = x
            }
        RightToLeft ->
            { x = y
            , y = width - x
            }


adaptSize : Flow -> ( Float, Float ) -> ( Float, Float )
adaptSize flow ( w, h ) =
    case flow of
        TopToBottom -> ( w, h )
        BottomToTop -> ( w, h )
        LeftToRight -> ( h, w )
        RightToLeft -> ( h, w )


firstCellAt : Flow ->  { a | width : Float, height : Float } -> ( Float, Float )
firstCellAt flow bounds =
    case flow of
        TopToBottom -> ( 0, 0 )
        BottomToTop -> ( 0, bounds.height - Cell.height )
        LeftToRight -> ( 0, 0 )
        RightToLeft -> ( bounds.width - Cell.width, 0 )


toString : Flow -> String
toString flow =
    case flow of
        TopToBottom -> "ttb"
        BottomToTop -> "btt"
        LeftToRight -> "ltr"
        RightToLeft -> "rtl"
