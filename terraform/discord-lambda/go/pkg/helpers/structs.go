package helpers

type DiscordCommand struct {
	Type              float64 `json:"type"`
	Data struct {
		Name string `json:"name"`
	} `json:"data"`
}
