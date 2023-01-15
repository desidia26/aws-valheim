package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
)

type RegisterCommandPayload struct {
	Name 				string `json:"name"`
	Description string `json:"description"`
	Type 				int    `json:"type"`
}

type Config struct {
	BotToken string `json:"bot_token"`
	AppID    string `json:"app_id"`
	GuildID  string `json:"guild_id"`
}

func loadConfig(file string) (*Config, error) {
	// Read the file
	data, err := ioutil.ReadFile(file)
	if err != nil {
		return nil, fmt.Errorf("could not read config file: %v", err)
	}
	// Unmarshal the json data
	var config Config
	err = json.Unmarshal(data, &config)
	if err != nil {
		return nil, fmt.Errorf("could not parse config file: %v", err)
	}
	return &config, nil
}

func readCommandsFromFile(file string) ([]RegisterCommandPayload, error) {
	// Read the file
	data, err := ioutil.ReadFile(file)
	if err != nil {
		return nil, fmt.Errorf("could not read file: %v", err)
	}

	// Unmarshal the json data
	var commands []RegisterCommandPayload
	err = json.Unmarshal(data, &commands)
	if err != nil {
			return nil, fmt.Errorf("could not parse json data: %v", err)
	}

	return commands, nil
}

func sendJSON(url string, payload RegisterCommandPayload, token string) error {
	// Marshal the payload into json
	jsonPayload, err := json.Marshal(payload)
	if err != nil {
			return err
	}
	// Create a new http client
	client := &http.Client{}
	// Create a new post request
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonPayload))
	if err != nil {
		return err
	}
	// Set the content type to json
	req.Header.Set("Authorization", fmt.Sprintf("Bot %s", token))
	req.Header.Set("Content-Type", "application/json")
	// Send the request
	resp, err := client.Do(req)
	if err != nil {
			return err
	}
	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
	}
	bodyString := string(bodyBytes)
	fmt.Println(bodyString)
	// Close the response body
	defer resp.Body.Close()
	return nil
}

func main() {
	config, err := loadConfig("./discordConfig.json")
	if err != nil {
		fmt.Println("Failed to load config!!!")
		fmt.Println(err)
		os.Exit(1)
	}
	commands, err := readCommandsFromFile("./commands.json");
	if err != nil {
		fmt.Println("Failed to load config!!!")
		os.Exit(1)
	}
	url := fmt.Sprintf("https://discord.com/api/v8/applications/%s/guilds/%s/commands", config.AppID, config.GuildID)
	fmt.Println(url)
	for _, cmd := range commands {
		sendJSON(url, cmd, config.BotToken)
	}
}
