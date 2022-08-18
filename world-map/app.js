const locationEu = document.querySelector("#location-eu");
const locationUs = document.querySelector("#location-us");
const locationAp = document.querySelector("#location-ap");
const Page = {
  eu: {
    links: {
      eu: document.querySelector("#eu-to-eu"),
      us: document.querySelector("#eu-to-us"),
      ap: document.querySelector("#eu-to-ap"),
    },
    pin: document.querySelector("#pin-eu"),
    cluster: document.querySelector("#k8s-eu"),
    ingress: document.querySelector("#ingress-eu"),
  },
  us: {
    links: {
      eu: document.querySelector("#us-to-eu"),
      us: document.querySelector("#us-to-us"),
      ap: document.querySelector("#us-to-ap"),
    },
    pin: document.querySelector("#pin-us"),
    cluster: document.querySelector("#k8s-us"),
    ingress: document.querySelector("#ingress-us"),
  },
  ap: {
    links: {
      eu: document.querySelector("#ap-to-eu"),
      us: document.querySelector("#ap-to-us"),
      ap: document.querySelector("#ap-to-ap"),
    },
    pin: document.querySelector("#pin-ap"),
    cluster: document.querySelector("#k8s-ap"),
    ingress: document.querySelector("#ingress-ap"),
  },
};

resetLinks();

locationEu.addEventListener("change", (event) => {
  event.preventDefault();
  store.dispatch(Action.setCurrentLocation("eu"));
});
locationUs.addEventListener("change", (event) => {
  event.preventDefault();
  store.dispatch(Action.setCurrentLocation("us"));
});
locationAp.addEventListener("change", (event) => {
  event.preventDefault();
  store.dispatch(Action.setCurrentLocation("ap"));
});

const store = (window.store = createStore(
  function (state, action) {
    switch (action.type) {
      case "location/set":
        return { ...state, currentLocation: action.payload };
      case "response/record":
        return {
          ...state,
          lastDestination: action.payload.locationName,
          lastResponseAt: action.payload.receviedAt,
          state: "idle",
        };
      case "response/reset": {
        return { ...state, lastDestination: "unknown" };
      }
      case "response/error": {
        return { ...state, state: "idle", lastDestination: "unknown" };
      }
      case "request/start":
        return { ...state, state: "in-progress" };
      default:
        return state;
    }
  },
  {
    currentLocation: "unknown",
    state: "idle",
    lastDestination: "unknown",
    lastResponseAt: new Date().toISOString(),
  }
));

function render(state, previousState) {
  if (previousState.currentLocation !== state.currentLocation) {
    switch (state.currentLocation) {
      case "eu":
        locationEu.setAttribute("checked", true);
        locationUs.removeAttribute("checked");
        locationAp.removeAttribute("checked");
        break;
      case "us":
        locationEu.removeAttribute("checked");
        locationUs.setAttribute("checked", true);
        locationAp.removeAttribute("checked");
        break;
      case "ap":
        locationEu.removeAttribute("checked");
        locationUs.removeAttribute("checked");
        locationAp.setAttribute("checked", true);
      default:
        locationEu.removeAttribute("checked");
        locationUs.removeAttribute("checked");
        locationAp.removeAttribute("checked");
        break;
    }
  }
  if (
    previousState.lastDestination !== state.lastDestination &&
    Page[state.currentLocation]?.links?.[state.lastDestination]
  ) {
    Page[state.currentLocation].links[state.lastDestination].classList.remove(
      "dn"
    );
    switch (state.lastDestination) {
      case "us":
        Page.us.cluster.style.fill = "#326CE5";
        Page.eu.cluster.style.fill = "#BFBFBF";
        Page.ap.cluster.style.fill = "#BFBFBF";
        break;
      case "eu":
        Page.us.cluster.style.fill = "#BFBFBF";
        Page.eu.cluster.style.fill = "#326CE5";
        Page.ap.cluster.style.fill = "#BFBFBF";
        break;
      case "ap":
        Page.us.cluster.style.fill = "#BFBFBF";
        Page.eu.cluster.style.fill = "#BFBFBF";
        Page.ap.cluster.style.fill = "#326CE5";
        break;
      default:
        Page.us.cluster.style.fill = "#BFBFBF";
        Page.eu.cluster.style.fill = "#BFBFBF";
        Page.ap.cluster.style.fill = "#BFBFBF";
        break;
    }
  }

  if (previousState.currentLocation !== state.currentLocation) {
    switch (state.currentLocation) {
      case "us":
        Page.us.pin.style.fill = "#C32826";
        Page.eu.pin.style.fill = "#BFBFBF";
        Page.ap.pin.style.fill = "#BFBFBF";
        Page.us.ingress.classList.remove("dn");
        Page.eu.ingress.classList.add("dn");
        Page.ap.ingress.classList.add("dn");
        break;
      case "eu":
        Page.us.pin.style.fill = "#BFBFBF";
        Page.eu.pin.style.fill = "#C32826";
        Page.ap.pin.style.fill = "#BFBFBF";
        Page.us.ingress.classList.add("dn");
        Page.eu.ingress.classList.remove("dn");
        Page.ap.ingress.classList.add("dn");
        break;
      case "ap":
        Page.us.pin.style.fill = "#BFBFBF";
        Page.eu.pin.style.fill = "#BFBFBF";
        Page.ap.pin.style.fill = "#C32826";
        Page.us.ingress.classList.add("dn");
        Page.eu.ingress.classList.add("dn");
        Page.ap.ingress.classList.remove("dn");
        break;
      default:
        Page.us.pin.style.fill = "#BFBFBF";
        Page.eu.pin.style.fill = "#BFBFBF";
        Page.ap.pin.style.fill = "#BFBFBF";
        Page.us.ingress.classList.add("dn");
        Page.eu.ingress.classList.add("dn");
        Page.ap.ingress.classList.add("dn");
        break;
    }
  }
}

const Action = {
  setCurrentLocation(locationName) {
    return { type: "location/set", payload: locationName };
  },
  recordResponse(locationName, receviedAt) {
    return { type: "response/record", payload: { locationName, receviedAt } };
  },
  startRequest() {
    return { type: "request/start" };
  },
  recordError() {
    return { type: "response/error" };
  },
  resetDestination() {
    return { type: "response/reset" };
  },
};

const requestReply = RequestReplyWorker(2000);
const reset = ResetLinksWorker(1500);
let cache = {
  previousState: store.getState(),
  oldTimestamp: Date.now(),
  fps: 60,
  delta: 0,
};

render(store.getState(), {});
Loop(Date.now());
store.dispatch(Action.setCurrentLocation("eu"));

function Loop(timestamp) {
  cache.delta = timestamp - cache.oldTimestamp;
  cache.oldTimestamp = timestamp;
  cache.fps = Math.round(1 / (cache.delta / 1000));
  const state = store.getState();
  const previousState = cache.previousState;
  cache.previousState = state;

  requestReply(Date.now(), previousState);
  reset(Date.now(), previousState);

  render(state, previousState);
  requestAnimationFrame(Loop);
}

function RequestReplyWorker(ms = 5000) {
  let previousDate = Date.now();
  let isInProgress = false;
  return (now = Date.now(), state) => {
    if (isInProgress) {
      return;
    }

    if (now - previousDate > ms) {
      previousDate = now;
      if (state.currentLocation !== "unknown") {
        store.dispatch(Action.startRequest());
        isInProgress = true;
        fetch(`/${state.currentLocation}`)
          .then((response) => response.text())
          .then((response) => {
            if (/Singapore/i.test(response)) {
              store.dispatch(
                Action.recordResponse("ap", new Date().toISOString())
              );
            }
            if (/London/i.test(response)) {
              store.dispatch(
                Action.recordResponse("eu", new Date().toISOString())
              );
            }
            if (/Fremont/i.test(response)) {
              store.dispatch(
                Action.recordResponse("us", new Date().toISOString())
              );
            }
          })
          .catch((error) => {
            console.log(error);
            store.dispatch(Action.recordError());
          })
          .finally(() => {
            isInProgress = false;
          });
      }
    }
  };
}

function ResetLinksWorker(ms = 1000) {
  return (now = Date.now(), state) => {
    if (
      state.lastDestination !== "unknown" &&
      now - new Date(state.lastResponseAt).valueOf() > ms
    ) {
      resetLinks();
      store.dispatch(Action.resetDestination());
    }
  };
}

function resetLinks() {
  for (const locationA of ["eu", "ap", "us"]) {
    for (const locationB of ["eu", "ap", "us"]) {
      Page[locationA].links[locationB].classList.add("dn");
    }
  }
}

function createStore(reducer, initialState) {
  let currentState = initialState;
  let listeners = [];

  return { dispatch, getState, subscribe };

  function dispatch(action) {
    currentState = reducer(currentState, action);
    console.log("dispatch", action, currentState);
    listeners.slice(0).forEach((it) => it(currentState));
  }

  function subscribe(listener) {
    listeners.push(listener);
  }

  function getState() {
    return currentState;
  }
}

async function wait(ms = 1000) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
