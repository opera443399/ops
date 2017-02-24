package main

import (
    "fmt"
    "log"
    "time"
    "net/http"
    "io/ioutil"
    "strings"
    "strconv"
    "os"
)


type taskstat struct {
    success int
    failure int
}


func checkError(err error, method string) bool {
    if err != nil {
        log.Printf("[E] %s : %v", method, err)
        return true
    }
    return false
}


func getHosts() ([]string) {
    var hosts []string
    data, err := ioutil.ReadFile("hosts.txt")
    if checkError(err, "outil.ReadFile") {
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


func request_url(cnt int, url string, ch chan string, stat *taskstat) {
    head, err := http.Head(url)
    if checkError(err, "http.Head") {
        ch <- "[" + strconv.Itoa(cnt)  + "]" + url
        ch <- "[" + strconv.Itoa(cnt) + "]failed"
        stat.failure += 1
        return
    }
    status := head.Status
    ch <- "[" + strconv.Itoa(cnt) +  "]" + url + " : " + status
    stat.success += 1

    res, err := http.Get(url)
    if checkError(err, "http.Get") {
        stat.failure += 1
        return
    }

    data, err := ioutil.ReadAll(res.Body)
    if checkError(err, "ioutil.ReadAll") {
        stat.failure += 1
        return
    }
    ch <- "[" + strconv.Itoa(cnt) +  "]" + "Got size: " + strconv.Itoa(len(data))
    stat.success += 1

}


func main() {
    var cnt int = 10
    var err error
    var hosts []string
    var stat = taskstat{0, 0}

    dt_start := time.Now()
    if len(os.Args) > 2 {
        cnt, err = strconv.Atoi(os.Args[1])
        if checkError(err, "strconv.Atoi") {
            return
        }

        if len(os.Args) == 3 {
            hosts = append(hosts, os.Args[2]) 
        } else {
            hosts = getHosts()
        }
    }

    for _, url := range hosts {
        ch := make(chan string)
        for i := 0; i < cnt; i++ {
            go request_url(i, "http://"+url, ch, &stat)
        }

        for t := 0; t < cnt; t++ {
            fmt.Println(<-ch)
            fmt.Println(<-ch)
        }
    }
    fmt.Printf("success: %d, failure %d\n", stat.success, stat.failure)
    log.Printf("Time Cost: %v", time.Since(dt_start))
}
