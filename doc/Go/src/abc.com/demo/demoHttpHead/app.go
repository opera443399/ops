/*
# demoHttpHead
# 2017/10/20
*/ 

package main

import (
    "flag"
    "fmt"
    "log"
    "sync"
    "time"
    "net/http"
    "io/ioutil"
    "strings"
    "strconv"
)


type taskState struct {
    v map[string]int
    mux sync.Mutex
}

func (ts *taskState) Inc(key string) {
    ts.mux.Lock()
    ts.v[key]++
    ts.mux.Unlock()
}

func (ts *taskState) Value(key string) int {
    ts.mux.Lock()
    defer ts.mux.Unlock()
    return ts.v[key]
}


func handleError(err error, method string) bool {
    if err != nil {
        log.Printf("[E] %s : %v", method, err)
        return true
    }
    return false
}


func getHosts() ([]string) {
    var hosts []string
    data, err := ioutil.ReadFile("urls.txt")
    if handleError(err, "ioutil.ReadFile") {
        return hosts
    }

    for _, h := range strings.Split(string(data), "\n") {
        if h == "" {
            continue
        }
        hosts = append(hosts, h)
    }
    return hosts
}


func handleHttpHeadReq(seq int, url string, ch chan string, stat *taskState) {
    head, err := http.Head(url)
    if handleError(err, "http.Head") {
        stat.Inc("failure")

        ch <- "[" + strconv.Itoa(seq)  + "]" + url + " : failed."
        return
    }

    stat.Inc("success")
    status := head.Status
    ch <- "[" + strconv.Itoa(seq) +  "]" + url + " : " + status
}


func main() {
    dtStart := time.Now()
    cnt := flag.Int("c", 10, "[] set N times to request the http url.")
    fromCfg := flag.Bool("f", false, "[] parse urls from file: [urls.txt] or not?")

    flag.Parse()

    var stat = taskState{v: make(map[string]int)}
    var hosts []string

    if *fromCfg == true {
        hosts = getHosts()
    } else{
        hosts = flag.Args()
    }

    for _, url := range hosts {
        ch := make(chan string)
        for i := 0; i < *cnt; i++ {
            go handleHttpHeadReq(i, url, ch, &stat)
        }

        for t := 0; t < *cnt; t++ {
            fmt.Println(<-ch)
        }
    }
    log.Printf("success: %d, failure: %d, Time Cost: %v\n", stat.Value("success"), stat.Value("failure"), time.Since(dtStart))
}
