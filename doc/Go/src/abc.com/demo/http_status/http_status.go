/*
# go demo: website_status
# 2017/3/9
*/ 

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
    if checkError(err, "ioutil.ReadFile") {
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
        stat.failure += 1
        ch <- "[" + strconv.Itoa(cnt)  + "]" + url + " : failed."
        return
    }
    stat.success += 1
    status := head.Status
    ch <- "[" + strconv.Itoa(cnt) +  "]" + url + " : " + status
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
        }
    }
    fmt.Printf("\nsuccess: %d, failure: %d\n", stat.success, stat.failure)
    log.Printf("Time Cost: %v", time.Since(dt_start))
}
