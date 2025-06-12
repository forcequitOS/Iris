# Iris
## A command-line server to give you a standard HTTP API for Apple's Foundation Models framework.
<sub>Iris technically stands for "Intelligence Redirection Integration System", if you were wondering.</sub>

**What do I need?**

- A Mac with Apple Silicon that has Apple Intelligence enabled and is running macOS Tahoe 26 or later (This tool can hypothetically run on an iPhone, iPad, or Vision Pro, with Apple Intelligence and appleOS 26 too, though! Just would need a basic GUI app written around it, which I'll truthfully do myself at some point.)
- A way to send HTTP POST requests

**Why and how is this useful?**

To allow developers (like possibly you reading this, and definitely myself) to take advantage of the on-device preinstalled LLM without having to write whatever you're doing as a native application. Electron apps and random Node.js projects can take advantage of this, I think at least.

**More details please!**

Rather decent compatibility with the Ollama and OpenAI APIs, other than text streaming, images, and chat support being the main exceptions.

Iris supports the following environment variables:

`IRIS_PORT`: The port number you want Iris to run on. Default is 2526 if none is specified.

`IRIS_SYSTEM`: System instructions for the model. If a system prompt is specified in an HTTP request, that will take priority.

`IRIS_TEMPERATURE`: Model temperature as a typical numeric value. HTTP request takes priority.

`IRIS_MAX_TOKENS`: Maximum amount of tokens that will be used when generating a response. HTTP request, again, takes priority.

`IRIS_LOCAL_ONLY`: When set to true, the Iris server will only be broadcasted to localhost and won't be accessible from other devices on the network, if set to false or not set at all, the Iris server will remain accessible to all devices on the same network.

To use Iris, you just make an HTTP JSON POST request containing `prompt` as a string to the server's root (/). That's it. Additionally, you can specify...

`system`, your system prompt, obviously a text string

`temperature`, the LLM's temperature, numerical value

`max_tokens`, the maximum number of tokens that the LLM will use when generating a response, also a numerical value

And, if for whatever reason you don't like sending requests to /, for Ollama API compatibility, Iris also supports sending POST requests to /api/generate, and accepting a GET request for /api/tags (Although it literally provides nothing useful, there's only one model and there is no model parameter to change the model).

That's basically it. It's a rather simple tool. It also shows requests and the output from them and the time they were completed and also does some extra stuff to allow for decent error handling. If you don't like the request logs, just silence their output with &>/dev/null, and if you like them so much you want to save them to a file, just do > Iris.log.
