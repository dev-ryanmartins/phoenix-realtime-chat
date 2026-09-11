// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/phoenix_chat"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

const chatShell = document.querySelector("[data-chat-shell]")

if (chatShell) {
  const socket = new Socket("/socket", {
    params: {user_id: chatShell.dataset.userId},
  })
  const channel = socket.channel(chatShell.dataset.topic, {})
  const messageList = document.querySelector("[data-message-list]")
  const composer = document.querySelector("[data-composer]")
  const messageInput = document.querySelector("[data-message-input]")
  const connectionStatus = document.querySelector("[data-connection-status]")
  const memberCount = document.querySelector("[data-member-count]")
  const emptyState = document.querySelector("[data-empty-state]")

  const escapeHTML = (value) =>
    String(value).replace(/[&<>"']/g, (character) => ({
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#039;",
    })[character])

  const formatTime = (timestamp) =>
    new Intl.DateTimeFormat("pt-BR", {hour: "2-digit", minute: "2-digit"}).format(new Date(timestamp))

  const initials = (name) =>
    name
      .split(" ")
      .slice(0, 2)
      .map((part) => part[0])
      .join("")
      .toUpperCase()

  const renderMessage = (message) => {
    const item = document.createElement("article")
    item.className = "group flex gap-3 px-5 py-3 transition hover:bg-slate-50/80 dark:hover:bg-slate-900/40"
    item.dataset.messageId = message.id
    item.innerHTML = `
      <div class="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-2xl bg-teal-100 text-xs font-bold text-teal-700 dark:bg-teal-400/15 dark:text-teal-300">${escapeHTML(initials(message.user.display_name))}</div>
      <div class="min-w-0 flex-1">
        <div class="flex items-baseline gap-2">
          <span class="text-sm font-semibold text-slate-900 dark:text-white">${escapeHTML(message.user.display_name)}</span>
          <time class="text-[11px] text-slate-400 dark:text-slate-500">${formatTime(message.inserted_at)}</time>
        </div>
        <p class="mt-1 whitespace-pre-wrap break-words text-sm leading-6 text-slate-600 dark:text-slate-300"></p>
      </div>
    `
    item.querySelector("p").textContent = message.body
    messageList.appendChild(item)
    emptyState?.classList.add("hidden")
    messageList.parentElement.scrollTop = messageList.parentElement.scrollHeight
  }

  const renderHistory = (messages) => {
    messageList.innerHTML = ""
    messages.forEach(renderMessage)
    if (messages.length === 0) emptyState?.classList.remove("hidden")
  }

  channel.on("new_msg", renderMessage)
  channel.on("presence", ({count}) => {
    if (memberCount) memberCount.textContent = `${count} ${count === 1 ? "pessoa" : "pessoas"} online`
  })

  socket.connect()

  channel
    .join()
    .receive("ok", ({messages, member_count}) => {
      connectionStatus.textContent = "conectado"
      connectionStatus.className = "text-xs font-medium text-emerald-600 dark:text-emerald-400"
      if (memberCount) memberCount.textContent = `${member_count} ${member_count === 1 ? "pessoa" : "pessoas"} online`
      renderHistory(messages)
    })
    .receive("error", () => {
      connectionStatus.textContent = "erro de conexão"
      connectionStatus.className = "text-xs font-medium text-rose-600 dark:text-rose-400"
    })

  composer?.addEventListener("submit", (event) => {
    event.preventDefault()
    const body = messageInput.value.trim()
    if (!body || channel.state !== "joined") return

    channel.push("new_msg", {body})
    messageInput.value = ""
    messageInput.focus()
  })
}

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

