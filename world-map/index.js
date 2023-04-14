const http = require("http");
const { readFileSync } = require("fs");

const endpoints = JSON.parse(process.argv.slice(2)[0]);

const requestListener = function (req, res) {
  switch (req.url) {
    case "/": {
      const html = readFileSync(__dirname + "/index.html", "utf-8");
      res.setHeader("Content-Type", "text/html");
      res.writeHead(200);
      res.end(html);
      break;
    }
    case "/app.js": {
      const js = readFileSync(__dirname + "/app.js", "utf-8");
      res.setHeader("Content-Type", "text/javascript");
      res.writeHead(200);
      res.end(js);
      break;
    }
    case "/eu": {
      http.get(endpoints.eu, function (response) {
        response.pipe(res, { end: true });
      });
      break;
    }
    case "/us": {
      http.get(endpoints.us, function (response) {
        response.pipe(res, { end: true });
      });
      break;
    }
    case "/ap": {
      http.get(endpoints.ap, function (response) {
        response.pipe(res, { end: true });
      });
      break;
    }
    default:
      res.writeHead(404);
      res.end();
      break;
  }
};

const server = http.createServer(requestListener);
server.listen(8082);
