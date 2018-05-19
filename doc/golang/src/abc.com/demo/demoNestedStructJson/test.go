/*
 * how to convert nested struct to json in golang
 *
 * pc@2017/8/28
*/

package main

import (
        "fmt"
        "encoding/json"
)


type tasksList struct {
    ID string `json:"id"`
    Hostname string `json:"hostname"`
}

type servicesList struct {
    Service string `json:"service"`
    Tasks []tasksList `json:"tasks"`
}

type dataList struct {
    Services []servicesList `json:"data"`
}

func main() {
    var cc servicesList
    var dd dataList

    cc.Service = "s1"
    cc.Tasks = append(cc.Tasks, tasksList{ID: "aaa", Hostname: "a1"})
    
    dd.Services = append(dd.Services, cc)

    cc.Service = "s2"
    cc.Tasks = append(cc.Tasks, tasksList{ID: "bbb", Hostname: "b1"})
    
    dd.Services = append(dd.Services, cc)
    
    buf, err := json.Marshal(dd)
    if err != nil {
        fmt.Println("json err:", err)
    }
    fmt.Printf("%s\n", buf)
}

