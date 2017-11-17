package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"time"

	"github.com/coreos/etcd/clientv3"
	"k8s.io/kubernetes/pkg/api"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
)

var endpoint string
var prefix string
var requestTimeout = time.Duration(3) * time.Second

func init() {
	flag.StringVar(&endpoint, "endpoint", "http://127.0.0.1:2379", "Etcd endpoint.")
	flag.StringVar(&prefix, "prefix", "/k8s", "Etcd prefix")
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
	d := api.Codecs.UniversalDeserializer()
	fmt.Printf("d: %T\n", d)
	mediaType := "application/vnd.kubernetes.protobuf"
	info, ok := runtime.SerializerInfoForMediaType(api.Codecs.SupportedMediaTypes(), mediaType)
	if !ok {
		log.Fatal(mediaType)
	}
	fmt.Printf("info: %T\n", info)

	for _, kv := range resp.Kvs {
		fmt.Printf("Value: %T\n", kv.Value)
		obj, _, err := d.Decode(kv.Value, &schema.GroupVersionKind{Kind: "Server", Version: "v1"}, nil)
		fmt.Printf("obj: %T\n", obj)
        	if err != nil {
                	log.Fatal(err)
	        }

	}

}
