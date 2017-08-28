package main

import (
    "flag"

    "fmt"
    "log"
	"encoding/json"
    "net/http"
    
    "context"
    "github.com/docker/docker/api/types"
    "github.com/docker/docker/api/types/filters"
    "github.com/docker/docker/client"
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

    fmt.Println("Listening on port *:" + port)
    log.Fatal(http.ListenAndServe(":"+port, nil))
}


/*
 * curl 127.0.0.1/index
 *
*/

func index(w http.ResponseWriter, r *http.Request) {
    cli, err := client.NewEnvClient()
    if err != nil {
        panic(err)
    }
    
    //services
    fmt.Fprint(w, "├── services:\n")
    
    services, err := cli.ServiceList(context.Background(), types.ServiceListOptions{})
    if err != nil {
        panic(err)
    }

    for _, service := range services {
        fmt.Fprintf(w, "│   ├── %s\n", service.Spec.Name)
        
        //tasks
        
        f1 := filters.NewArgs()
        f1.Add("service", service.ID)
        f1.Add("desired-state", "running")
        tasks, err := cli.TaskList(context.Background(), types.TaskListOptions{
                                                                    Filters: f1,
                                                                })
        if err != nil {
            panic(err)
        }
        
        for _, task := range tasks {        
            //node
            
            f2 := filters.NewArgs()
            f2.Add("id", task.NodeID)
            nodes, err := cli.NodeList(context.Background(), types.NodeListOptions{
                                                                    Filters: f2,
                                                                })
            if err != nil {
                panic(err)
            }
            
            node := nodes[0]
            fmt.Fprintf(w, "│   │   ├── [%s] %s\n", task.ID, node.Description.Hostname)
        }
    }
    
}


/*
 * curl 127.0.0.1/api
 *
*/

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

func api(w http.ResponseWriter, r *http.Request) {
    var dd dataList
        
    cli, err := client.NewEnvClient()
    if err != nil {
        panic(err)
    }
    
    //services
    
    services, err := cli.ServiceList(context.Background(), types.ServiceListOptions{})
    if err != nil {
        panic(err)
    }

    for _, service := range services {
        var ss servicesList
        
        ss.Service = service.Spec.Name
        
        //tasks
        
        f1 := filters.NewArgs()
        f1.Add("service", service.ID)
        f1.Add("desired-state", "running")
        tasks, err := cli.TaskList(context.Background(), types.TaskListOptions{
                                                                    Filters: f1,
                                                                })
        if err != nil {
            panic(err)
        }
        
        for _, task := range tasks {
            //node
            
            f2 := filters.NewArgs()
            f2.Add("id", task.NodeID)
            nodes, err := cli.NodeList(context.Background(), types.NodeListOptions{
                                                                    Filters: f2,
                                                                })
            if err != nil {
                panic(err)
            }
            
            node := nodes[0]
            ss.Tasks = append(ss.Tasks, tasksList{ID: task.ID, Hostname: node.Description.Hostname})
        }
        
        dd.Services = append(dd.Services, ss)
    }
    
    json.NewEncoder(w).Encode(dd)
    
}
