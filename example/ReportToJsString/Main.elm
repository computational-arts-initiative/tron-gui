port module ReportToJsString.Main exposing (main)


import Html

import Gui.Style.Theme as Theme
import Gui.Style.Dock as Dock
import Gui.Option as Option
import Gui.WithGui as WithGui exposing (ProgramWithGui)


import Example.Goose.Main as Example
import Example.Goose.Model as Example
import Example.Goose.Msg as Example
import Example.Goose.Gui as ExampleGui


{-
-- Change to `Default` example
-- by just commenting out `.Goose` imports above
-- and removing the comment here
import Example.Default.Main as Example
import Example.Default.Model as Example
import Example.Default.Msg as Example
import Example.Default.Gui as ExampleGui
-}



port sendUpdate : ( String, String ) -> Cmd msg


main : ProgramWithGui () Example.Model Example.Msg
main =
    WithGui.element
        (Option.toHtml Dock.middleRight Theme.dark)
        (Option.sendStrings
            { transmit = sendUpdate
            }
        )
        { for = ExampleGui.for
        , init = always Example.init
        , view = always <| Html.div [] [] -- Example.view
        , update = Example.update
        , subscriptions = always Sub.none
        }


