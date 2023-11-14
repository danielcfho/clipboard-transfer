import sys
import _tkinter as tk
import hashlib
import zipfile

class MainWindow(Tk):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.title("PowerShell GUI")
        self.geometry("470x500")
        self.minsize = (470, 500)
        self.maxsize = (470, 500)

        # Define controls
        self.encode_button = Button(self, text="Encode", command=self.encode_file)
        self.encode_button.place(x=5, y=5, width=120, height=50)

        self.decode_button = Button(self, text="Decode", command=self.decode_file)
        self.decode_button.place(x=5, y=350, width=120, height=50)

        self.output_textbox = Text(self, height=5, width=40)
        self.output_textbox.place(x=5, y=325)

        self.browser_button = Button(self, text="Browse...", command=self.browse)
        self.browser_button.place(x=360, y=325, width=70, height=20)

        self.checkbox = Checkbutton(self, text="Clear afterwards")
        self.checkbox.place(x=140, y=9)

        self.label = Label(self, text="Drop files or folders here:")
        self.label.place(x=137, y=39)

        self.clear_list_button = Button(self, text="Clear List", command=self.clear_list)
        self.clear_list_button.place(x=330, y=30, width=5)

        self.encode_label = Label(self, text="Encode MD5:")
        self.encode_label.place(x=5, y=270)

        self.decode_label = Label(self, text="Decode MD5:")
        self.decode_label.place(x=5, y=410)

        self.list_box = Listbox(self, allowdrop=True)
        self.list_box.place(x=5, y=60, height=200, width=445)
        self.list_box.bind('<<DragOver>>', self.drag_over)
        self.list_box.bind('<<DragDrop>>', self.drag_drop)
        self.list_box.bind('<<Delete>>', self.delete_item)
        self.list_box.bind('<<BackSpace>>', self.delete_item)

        self.status_bar = Label(self, text="Ready")
        self.status_bar.place(x=0, y=480, width=470, height=20)

        # Wire up events
        self.encode_button.config(command=self.encode_file)
        self.decode_button.config(command=self.decode_file)
        self.browser_button.config(command=self.browse)
        self.clear_list_button.config(command=self.clear_list)

    def encode_file(self):
        temp_zip_file = "temp.zip"

        # Compress the selected files and folders to a temporary zip file
        with zipfile.ZipFile(temp_zip_file, "w") as zip_file:
            for item in self.list_box.get(0, END):
                zip_file.write(item)

        # Encode the zip file to Base64
        with open(temp_zip_file, "rb") as binary_file:
            base64_string = hashlib.md5(binary_file.read()).hexdigest()

        # Write the Base64 string to the clipboard
        self.clipboard_append(base64_string)

        # Update the status bar
        self.status_bar.config(text="Binary txt copied to Clipboard, run Decode from other machine.")

    def decode_file(self):
        base64_string = self.clipboard_get()

        # Decode the Base64 string to binary data
        binary_data = bytes.fromhex(base64_string)

        # Write the binary data to a temporary file
        with open("temp.zip", "wb") as binary_file:
            binary_file.write(binary_data)

        # Extract the contents of the zip file to the output directory
        with zipfile.ZipFile("temp.zip", "r") as zip_file:
            zip_file.extractall(self.output_textbox.get("1.0", END))

        # Update the status bar
        self.status_bar.config(text="Base64 file decoded successfully.")

    def browse(self):
        folder_browser_dialog = Tk()
        folder_browser_dialog.withdraw()
        selected_path = folder_browser_dialog.askdirectory()
        folder_browser_dialog.destroy()

        if selected_path:
            self.output_textbox.delete("1.0", END)
            self.output_textbox.insert("1.0", selected_path)

    def drag_over(self, event):
        if event.data.getDataPresent("FileNameW"):
            event.effect = "copy"
        else:
            event.effect = "none"

    def drag_drop(self, event):
        for filename in event.data.getData("FileNameW"):
            if filename not in self.list_box.get(0, END):
                self.list_box.insert(END, filename)

        # Update the status bar
        self.status_bar.config(text="List contains {} items".format(self.list_box.size()))

    def delete_item(self, event):
        selected_indices = self.list_box.curselection()
        for index in reversed(selected_indices):
            self.list_box.delete(index)

    def clear_list(self):
        self.list_box.delete(0, END)

    def clipboard_get(self):
        import pyperclip
        return pyperclip.paste()

    def clipboard_append(self, text):
        import pyperclip
        pyperclip.copy(text)

if __name__ == "__main__":
    root = MainWindow()
    root.mainloop()
