package discord

import "time"

type DiscordCommand struct {
	Type              float64 `json:"type"`
	Data struct {
		Name string `json:"name"`
	} `json:"data"`
}

type DiscordCommandResponse struct {
	Type int `json:"type"`
	Data struct {
		Content string `json:"content"`
	} `json:"data"`
}

type ServerStatus struct {
	LastStatusUpdate time.Time     `json:"last_status_update"`
	Error            error         `json:"error"`
	ServerName       string        `json:"server_name"`
	ServerType       string        `json:"server_type"`
	Platform         string        `json:"platform"`
	PlayerCount      int           `json:"player_count"`
	PasswordProtected bool          `json:"password_protected"`
	VacEnabled       bool          `json:"vac_enabled"`
	Port             int           `json:"port"`
	SteamID          int64         `json:"steam_id"`
	Keywords         string        `json:"keywords"`
	GameID           int           `json:"game_id"`
	Players          []interface{} `json:"players"`
}

type DiscordMessage struct {
	Username string `json:"username"`
	Content  string `json:"content"`
}