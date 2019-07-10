import nigui
import nigui/msgbox
include db

app.init()
# Initialization is mandatory.

var window = newWindow("GraphNotes")
# Create a window with a given title:
# By default, a window is empty and not visible.
# It is played at the center of the screen.
# A window can contain only one control.
# A container can contain multiple controls.

window.width = 800
window.height = 600
# Set the size of the window

# window.iconPath = "example_01_basic_app.png"
# The window icon can be specified this way.
# The default value is the name of the executable file without extension + ".png"

var container = newLayoutContainer(Layout_Vertical)
# Create a container for controls.
# By default, a container is empty.
# It's size will adapt to it's child controls.
# A LayoutContainer will automatically align the child controls.
# The layout is set to clhorizontal.
window.add(container)
# Add the container to the window.

var buttonContainer = newLayoutContainer(Layout_Horizontal)
container.add(buttonContainer)
# buttonContainer.frame = newFrame()

var button = newButton("Add notes")
# Create a button with a given title.
buttonContainer.add(button)
# Add the button to the container.
var button2 = newButton("Open database")
buttonContainer.add(button2)
# var savelocButton = newButton("Save loc")
# buttonContainer.add(savelocButton)

# # Add a Label control:
# var label = newLabel("Label")
# container.add(label)

# Add a TextBox control:
var textBox = newTextBox("Enter your query...")
container.add(textBox)

var textArea = newTextArea()
# Create a multiline text box.
# By default, a text area is empty and editable.
container.add(textArea)
# Add the text area to the container.


### variables

var saveloc: string = "./"
textArea.addLine("Save location is " & saveloc)

# savelocButton.onClick = proc(event: ClickEvent) =
#   var dialog = newOpenDirectoryDialog

var query: string
textBox.onKeyDown = proc(event: KeyboardEvent)=
  if Key_Return.isDown():
    query = textBox.text
    textArea.addLine("Query is " & query)


button2.onClick = proc(event: ClickEvent) =
  let res = window.msgBox("Hello.\n\nThis message box is created with \"msgBox()\" and has three buttons.", "Title of message box", "Button 1", "Button 2", "Button 3")
  textArea.addLine("Message box closed, result = " & $res)

window.onCloseClick = proc(event: CloseClickEvent) =
  case window.msgBox("Do you want to quit?", "Quit?", "Quit", "Minimize", "Cancel")
  of 1: window.dispose()
  of 2: window.minimize()
  else: discard

container.onKeyDown = proc(event: KeyboardEvent) =
  # Ctrl + Q -> Quit application
  if Key_Q.isDown() and Key_ControlL.isDown():
    app.quit()

### functions
discard create_bibfile(saveloc)
var db: db_sqlite.DbConn
let dbfile: string = joinpath(saveloc, "notes2graphdb.sqlite")
if existsFile(dbfile):
  db = load_database(saveloc)
else:
  db = initialize_database(saveloc)


textArea.addLine("Database and bibfile loaded in the current directory.")

var notefile: string
button.onClick = proc(event: ClickEvent) =
# Set an event handler for the "onClick" event (here as anonymous proc).
  # textArea.addLine("Button 1 clicked, message box opened.")
  # window.alert("This is a simple message box.")
  # textArea.addLine("Message box closed.")
  var dialog = newOpenFileDialog()
  dialog.title = "Select note file..."
  dialog.multiple = false  # only a single file can be selected
  dialog.directory = "./"
  dialog.run()
  textArea.addLine("Note file: " & dialog.files[0])
  notefile = dialog.files[0]
  discard update(db, notefile)



window.show()
# Make the window visible on the screen.
# Controls (containers, buttons, ..) are visible by default.

app.run()
# At last, run the main loop.
# This processes incoming events until the application quits.
# To quit the application, dispose all windows or call "app.quit()".