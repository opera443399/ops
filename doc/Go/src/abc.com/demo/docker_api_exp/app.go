package main

import (
    "context"
    "fmt"

    "github.com/docker/docker/api/types"
    "github.com/docker/docker/api/types/filters"
    "github.com/docker/docker/client"
)

func main() {
    cli, err := client.NewEnvClient()
    if err != nil {
        panic(err)
    }
    
    //services
    fmt.Printf("├── services:\n")
    
    services, err := cli.ServiceList(context.Background(), types.ServiceListOptions{})
    if err != nil {
        panic(err)
    }

    for _, service := range services {
        fmt.Printf("    ├── %s[id=%s]\n", service.Spec.Name, service.ID[:10])
        
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
            fmt.Printf("        ├── %s", task.ID[:10])
            
            //nodes
            
            f2 := filters.NewArgs()
            f2.Add("id", task.NodeID)
            nodes, err := cli.NodeList(context.Background(), types.NodeListOptions{
                                                                    Filters: f2,
                                                                })
            if err != nil {
                panic(err)
            }

            for _, node := range nodes {
                fmt.Printf("[%s]\n", node.Description.Hostname)
            }
        }
    }
    

}

