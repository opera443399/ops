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



func checkError(err error, method string) {
    if err != nil {
        log.Fatalf("[E] %s : %v", method, err)
    }
}


func getHosts() ([]string) {
    data, err := ioutil.ReadFile("hosts.txt")
    checkError(err, "outil.ReadFile")

    var hosts []string
    for _, h := range strings.Split(string(data), "\n") {
        if h == "" {
            continue
        }
        hosts = append(hosts, h)
    }
    return hosts
}


func request_url(cnt int, url string, ch chan string) {
    head, err := http.Head(url)
    checkError(err, "http.Head")
    status := head.Status
    ch <- "[" + strconv.Itoa(cnt) +  "]" + url + " : " + status

    res, err := http.Get(url)
    checkError(err, "http.Get")

    data, err := ioutil.ReadAll(res.Body)
    checkError(err, "ioutil.ReadAll")
    ch <- "[" + strconv.Itoa(cnt) +  "]" + "Got size: " + strconv.Itoa(len(data))

}


func main() {
    var hosts []string

    dt_start := time.Now()
    if len(os.Args) > 1 {
        hosts = append(hosts, os.Args[1]) 
    } else {
        hosts = getHosts()
    }

    for _, url := range hosts {
        ch := make(chan string)
        for i := 0; i < 10; i++ {
            go request_url(i, "http://"+url, ch)
        }

        for t := 0; t < 10; t++ {
            fmt.Println(<-ch)
            fmt.Println(<-ch)
        }
        log.Printf("Time Cost: %v", time.Since(dt_start))
    }
}
