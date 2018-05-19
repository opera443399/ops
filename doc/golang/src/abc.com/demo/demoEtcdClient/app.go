/*
 * read data from k8s/etcd
 * depends on k8s related pkgs around version v1.8
*/
package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"time"

	"github.com/coreos/etcd/clientv3"
	"k8s.io/api/core/v1"
	"k8s.io/kubernetes/pkg/api"

	_ "k8s.io/kubernetes/pkg/api/install"
)

var endpoint string
var prefix string
var requestTimeout = time.Duration(3) * time.Second

func init() {
	flag.StringVar(&endpoint, "endpoint", "http://127.0.0.1:2379", "Etcd endpoint.")
	flag.StringVar(&prefix, "prefix", "/registry/pods/default", "Etcd prefix")
}

func main() {
	var cli *clientv3.Client
	flag.Parse()
	fmt.Printf("endpoint: %v\n", endpoint)
	fmt.Printf("prefix: %v\n", prefix)

	cfg := clientv3.Config{
		Endpoints:   []string{endpoint},
		DialTimeout: 5 * time.Second,
	}
	cli, err := clientv3.New(cfg)
	if err != nil {
		log.Fatal(err)
	}
	defer cli.Close()

	ctx, cancel := context.WithTimeout(context.Background(), requestTimeout)
	resp, err := cli.Get(ctx, prefix, clientv3.WithPrefix(), clientv3.WithSort(clientv3.SortByKey, clientv3.SortDescend))
	cancel()
	if err != nil {
		log.Fatal(err)
	}

	// try to decode
	decoder := api.Codecs.UniversalDeserializer()
	for _, kv := range resp.Kvs {
		fmt.Printf("kv.Key: %s \t kv.Value: %T\n", kv.Key, kv.Value)
		fmt.Printf("kv.Value: %v\n\n", kv.Value)

		obj, _, err := decoder.Decode(kv.Value, nil, nil)
		if err != nil {
			fmt.Printf("test")
			log.Fatal(err)
		}
		fmt.Printf("obj: %T\n", obj)

		objV1, _ := obj.(*v1.Pod)
		fmt.Printf("objV1: %T\n", objV1)
	}

}
