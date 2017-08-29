/*
 * docker api and sdk exp
 * api ref: https://docs.docker.com/engine/api/v1.3
 * sdk go: https://godoc.org/github.com/moby/moby/client
 
 * [howto] 
 * # curl -s --unix-socket /var/run/docker.sock http:/v1.30/nodes |jq . |more
 * # curl -s --unix-socket /var/run/docker.sock http:/v1.30/services |jq . |more
 * # curl -s --unix-socket /var/run/docker.sock http:/v1.30/tasks |jq . |more
 *
 * pc@2017/8/29
*/

package main

import (
    "flag"
    
    "strings"
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
    flag.StringVar(&port, "port", "8007", "listen to the given port.")
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
    
    //------ list services
    fmt.Fprint(w, "├── services:\n")
    
    services, err := cli.ServiceList(context.Background(), types.ServiceListOptions{})
    if err != nil {
        panic(err)
    }

    for _, service := range services {
        //------ get Ports
        this_ports := "" 
        if len(service.Spec.EndpointSpec.Ports) > 0 {
            pp := []string{}
            for _, pConfig := range service.Spec.EndpointSpec.Ports {
                pp = append(pp, fmt.Sprintf("*:%d->%d/%s",
                    pConfig.PublishedPort,
                    pConfig.TargetPort,
                    pConfig.Protocol,
                ))
            }
            this_ports = strings.Join(pp, ",")
        }
        
        fmt.Fprintf(w, "│   ├── %s \t %s \t %s\n", service.Spec.Name, this_ports, strings.Split(service.Spec.TaskTemplate.ContainerSpec.Image, "@")[0])
        
        
        //------ list nodes which running specific tasks
        f1 := filters.NewArgs()
        f1.Add("service", service.ID)
        f1.Add("desired-state", "running")
        tasks, err := cli.TaskList(context.Background(), types.TaskListOptions{
                                                                    Filters: f1,
                                                                })
        if err != nil {
            panic(err)
        }
        
        this_node := make(map[string]string)
        for _, task := range tasks {        
            //get node info
            
            f2 := filters.NewArgs()
            f2.Add("id", task.NodeID)
            nodes, err := cli.NodeList(context.Background(), types.NodeListOptions{
                                                                    Filters: f2,
                                                                })
            if err != nil {
                panic(err)
            }
            
            node := nodes[0]
            this_node[node.Description.Hostname] = node.Status.Addr
        }
        
        for k, v := range this_node {
            fmt.Fprintf(w, "│   │   ├── %s \t %s\n", k, v)
        }
        
    }
    
}


/*
 * curl 127.0.0.1/api
 *
*/

type tasksList struct {
    IP string `json:"ip"`
    Hostname string `json:"hostname"`
}

type servicesList struct {
    Service string `json:"service"`
    Ports string `json:"ports"`
    Image string `json:"image"`
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
    
    //------ list services
    services, err := cli.ServiceList(context.Background(), types.ServiceListOptions{})
    if err != nil {
        panic(err)
    }

    for _, service := range services {
        var ss servicesList
        var tt tasksList
        
        ss.Service = service.Spec.Name
        
        //------get Ports
        this_ports := ""
        if len(service.Spec.EndpointSpec.Ports) > 0 {
            pp := []string{}
            for _, pConfig := range service.Spec.EndpointSpec.Ports {
                pp = append(pp, fmt.Sprintf("*:%d->%d/%s",
                    pConfig.PublishedPort,
                    pConfig.TargetPort,
                    pConfig.Protocol,
                ))
            }
            this_ports = strings.Join(pp, ",")
        }
        
        ss.Ports = this_ports
        ss.Image = strings.Split(service.Spec.TaskTemplate.ContainerSpec.Image, "@")[0]
            
        //------list nodes which running specific tasks
        f1 := filters.NewArgs()
        f1.Add("service", service.ID)
        f1.Add("desired-state", "running")
        tasks, err := cli.TaskList(context.Background(), types.TaskListOptions{
                                                                    Filters: f1,
                                                                })
        if err != nil {
            panic(err)
        }
        
        this_node := make(map[string]string)
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
            this_node[node.Description.Hostname] = node.Status.Addr
        }
        
        for k, v := range this_node {
            tt.Hostname = k
            tt.IP = v
            ss.Tasks = append(ss.Tasks, tt)
        }
        
        dd.Services = append(dd.Services, ss)
    }
    
    json.NewEncoder(w).Encode(dd)
    
}
