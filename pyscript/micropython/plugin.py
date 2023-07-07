from pyscript import Plugin

plugin = Plugin("PyHelloWorld")

print("--------------------------------------")


from pyscript import Plugin, js

plugin = Plugin("PyHelloWorld")


@plugin.register_custom_element("py-hello-world")
class PyHelloWorld:
    def __init__(self, element):
        self.element = element

    def connect(self):
        self.element.innerHTML = "<div id='hello'>Hello World!</div>"
