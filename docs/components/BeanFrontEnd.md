# BeanFrontEnd™

The BeanFrontEnd is a fastAPI server that
serves static files to users.
The application is stateless, everything it needs is contained within its docker image.

It serves as the "frontend" of the exchange.

The trading JS file establishes an SSE connection to the BeanWebConnector™, that listens for the latest price updates and renders them in the UI.

```mermaid
flowchart
    user --> browser --> BeanFrontEnd
    subgraph BeanFrontEnd
        flaskRouter --> iapm@{share: rect, label: isAuthed middleware }
        iapm --> serve_static_file
    end
    authmemcached@{ shape: cyl, label: "Auth\nmemcached" }
    pgs@{shape: lin-cyl, label: "PostGres"}
    idxhtml@{ shape: doc, label: "index.html" }
    loginhtml@{ shape: doc, label: "login.html" }
    tradinghtml@{ shape: doc, label: "trading.html" }
    tradingjs@{ shape: doc, label: "trading.js" }
    ordhisthtml@{ shape: doc, label: "order_history.html" }
    iapm -- 1) Check for session--> authmemcached
    iapm -- 2) Create session --> pgs
    serve_static_file --/--> idxhtml
    serve_static_file --/login--> loginhtml
    serve_static_file --/trading--> tradinghtml
    serve_static_file --/static/js--> tradingjs
    serve_static_file -- /order_history --> ordhisthtml
    tradingjs --Establish\nHTTP/3 Websocket connection--> BeanWebConnector
```
