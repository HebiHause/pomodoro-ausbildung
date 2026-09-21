# 🍅 Pomodoro Timer

A minimal Pomodoro timer with a built-in to-do list and a weekly activity chart.
The backend is written in Free Pascal, the frontend is plain HTML / CSS / JavaScript.

![Demo](assets/demo.gif)

## Features

- **Three timer modes** – Pomodoro (25 min), Short Pause (5 min), Long Pause (15 min)
- **Automatic cycle** – a Long Pause after every 3rd completed Pomodoro
- **Full control** – Start / Pause, Reset and Skip buttons
- **Visual progress** – a circular progress indicator that fills as time passes
- **To-do list** – add, complete and delete tasks
- **Activity chart** – completed sessions for the last 7 days, saved to `graphic.json` so you can everytime see the progre
- **Focus mode** – click the "To-Do List" header to expand the list to full height

## 🎬 Preview

### Timer and modes
![Timer](assets/timer.gif)


### To-do list
![To-do list](assets/todo.gif)

### Activity chart
![Chart](assets/chart.gif)

## 🛠 Tech stack

| Layer    | Technology                                             |
|----------|--------------------------------------------------------|
| Backend  | Free Pascal, `fphttpapp`, `httproute`, `fpjson`         |
| Frontend | HTML5, CSS3 (Grid, Flexbox, `conic-gradient`), vanilla JS |
| Storage  | JSON file (`graphic.json`)                             |

## 🚀 Getting started

### Requirements
- [Free Pascal Compiler](https://www.freepascal.org/) 3.x 
- Windows (the app uses `ShellAPI` to open the browser automatically)

### Run

```bash
git clone https://github.com/HebiHause/pomodoro-ausbildung.git
cd <pomodoro-ausbildung>
fpc Pomodoro.pas
Pomodoro.exe
```

Your browser opens automatically at `http://localhost:8080`.
Run the program from the project folder, because `index.html` and `style.css` are loaded from the working directory.

## What this project covers

- Records and dynamic arrays (the task list)
- HTTP routing with `fphttpapp` and `httproute`
- Reading and writing JSON with `fpjson`
- Saving data to a file and loading it back
- A background thread for the server next to the main timer loop
- A frontend that talks to the backend with `fetch`

### API

| Route                       | Description                                  |
|-----------------------------|----------------------------------------------|
| `/`, `/style.css`           | Serve the frontend                           |
| `/timer-status`             | Current time as `mm:ss`                      |
| `/mode-status`              | Current mode (0 / 1 / 2)                     |
| `/session-request`          | Number of completed sessions                 |
| `/progress-conic-gradient`  | Progress in percent for the circle           |
| `/set-pomodoro`, `/set-short-pause`, `/set-long-pause` | Switch mode      |
| `/start-pause`, `/reset`, `/skip` | Timer controls                         |
| `/tasks`                    | All tasks as JSON                            |
| `/add-task`, `/task-done`, `/delete-task` | To-do list actions (POST, JSON) |
| `/graphic`                  | Sessions for the last 7 days as JSON         |

## 📁 Project structure

```
├── Pomodoro.pas      # entry point: routes, timer loop, session logging
├── procedures.pas    # request handlers and to-do list logic
├── index.html        # page structure and frontend logic
├── style.css         # styling
├── graphic.json      # session history (created automatically)
└── assets/           # GIFs for this README
```

## Next steps

- Confirm the addition of a task to the to-do list by pressing Enter

## 📄 License

MIT