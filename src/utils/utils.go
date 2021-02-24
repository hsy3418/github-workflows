package utils

import (
	b64 "encoding/base64"
	"fmt"
	"io/ioutil"
	"os"

	"sigs.k8s.io/yaml"
)

// Base64Decode is decode the encrypt strings
func Base64Decode(value string) string {
	uDec, _ := b64.URLEncoding.DecodeString(value)
	return string(uDec)
}

// Readfile reads fild from a path and return the contents
func Readfile(path string) ([]byte, error) {
	b, err := ioutil.ReadFile(path)
	if err != nil {
		return nil, err
	}
	return b, nil
}

// ConvertYamlTojson convert yaml format data to json format
func ConvertYamlTojson(raw []byte) (*string, error) {
	j2, err := yaml.YAMLToJSON(raw)

	if err != nil {
		fmt.Printf("err: %v\n", err)
		return nil, err
	}
	d := string(j2)
	return &d, nil
}

//CreateFile is to create a file by adding the contents
func CreateFile(fileName string, object string) (*os.File, error) {
	f, _ := os.Create(fileName)
	if _, err := f.WriteString(object); err != nil {
		return nil, err
	}
	return f, nil
}
