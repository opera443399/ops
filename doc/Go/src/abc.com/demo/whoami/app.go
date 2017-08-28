/*
 * from: https://github.com/emilevauge/whoamI/blob/master/app.go
 * howto: 
 * go get app.go
 * go run app.go
 * go install app.go
 * CGO_ENABLED=0 go build -a --installsuffix cgo --ldflags="-s" -o whoamI
 *
 * pc@2017/8/16
 *
*/

package main

import (
    "encoding/json"
    "flag"
    "fmt"
    "log"
    "sync"

    "net/http"
    "net/url"
    "os"
    "time"
)

var port string

func init() {
    flag.StringVar(&port, "port", "80", "listen the port as given.")
}

func main() {
    flag.Parse()
    // url: index
    http.HandleFunc("/", index)
    // url: others
    http.HandleFunc("/api", api)
    http.HandleFunc("/health", healthHandler)
    http.HandleFunc("/test", testHandler)
    fmt.Println("Listening on port *:" + port)
    log.Fatal(http.ListenAndServe(":"+port, nil))
}

/*
 * curl 127.0.0.1/test
 *
*/

func testHandler(w http.ResponseWriter, r *http.Request) {
    body := "[test] Hello World\n"
    w.Header().Set("Connection", "keep-alive")
    w.Header().Set("Content-Type", "text/plain")
    fmt.Fprint(w, body)
}


/*
 * curl 127.0.0.1/
 * curl 127.0.0.1/?wait=2s
 *
*/

func index(w http.ResponseWriter, req *http.Request) {

    u, _ := url.Parse(req.URL.String())
    queryParams := u.Query()
    wait := queryParams.Get("wait")
    if len(wait) > 0 {
        duration, err := time.ParseDuration(wait)
        if err == nil {
            fmt.Println("request will be delayed for :", duration)
            time.Sleep(duration)
        } else {
            log.Println("[E] ", err.Error())
            //fmt.Fprintln(w, "[E] ", err.Error())
        }
    }
    
    w.Header().Set("Connection", "close")
    
    hostname, _ := os.Hostname()
    fmt.Fprintln(w, "Hostname:", hostname)
    fmt.Fprintln(w, "\n---- Http Request Headers ----\n")
    req.Write(w)

    fmt.Fprintln(w, "\n---- Active Endpoint ----\n")
    fmt.Fprintln(w, "[howto] version: 0.7 \n",
                    "   curl 127.0.0.1/ \n",
                    "   curl 127.0.0.1/?wait=2s \n",
                    "   curl 127.0.0.1/test \n",
                    "   curl 127.0.0.1/api \n",
                    "   curl 127.0.0.1/health \n",
                    "   curl 127.0.0.1/health -d '302' \n",
                    "\n")
}


/*
 * curl 127.0.0.1/api
 *
*/

func api(w http.ResponseWriter, req *http.Request) {
    hostname, _ := os.Hostname()
    data := struct {
        Hostname string      `json:"hostname,omitempty"`
        Headers  http.Header `json:"headers,omitempty"`
    }{
        hostname,
        req.Header,
    }

    json.NewEncoder(w).Encode(data)
}


/*
 * curl 127.0.0.1/health
 * curl 127.0.0.1/health -d '404'
 *
*/

type healthState struct {
    StatusCode int
}

var currentHealthState = healthState{200}
var mutexHealthState = &sync.RWMutex{}

func healthHandler(w http.ResponseWriter, req *http.Request) {
    if req.Method == http.MethodPost {
        var statusCode int
        err := json.NewDecoder(req.Body).Decode(&statusCode)
        if err != nil {
            w.WriteHeader(http.StatusBadRequest)
            w.Write([]byte(err.Error()))
            log.Println(err.Error())
        } else {
            mutexHealthState.Lock()
            defer mutexHealthState.Unlock()

            currentHealthState.StatusCode = statusCode
            fmt.Println("Update 'health check' status code =", statusCode)
            fmt.Fprintln(w, statusCode)
        }
    } else {
        mutexHealthState.RLock()
        defer mutexHealthState.RUnlock()

        w.WriteHeader(currentHealthState.StatusCode)
        fmt.Println("Current 'health check' status code =", currentHealthState.StatusCode)
        fmt.Fprintln(w, currentHealthState.StatusCode)
    }
}
