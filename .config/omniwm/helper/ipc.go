package main

import (
	"bufio"
	"cmp"
	"encoding/json"
	"fmt"
	"maps"
	"net"
	"os"
	"slices"
	"strconv"
	"strings"
)

// OmniWM's IPC protocol, as omniwmctl 0.8.0 speaks it: one JSON request per connection,
// answered by one JSON line. OmniWM doesn't document it; when an update changes it, point
// OMNIWM_SOCKET at a socket that logs what omniwmctl sends to see the new requests.
const protocolVersion = 22

type client struct {
	socket string
	token  string
	sent   int
}

func newClient(socket string) (*client, error) {
	secret, err := os.ReadFile(socket + ".secret")
	if err != nil {
		return nil, fmt.Errorf("cannot read OmniWM's IPC secret (is IPC on in OmniWM's settings?): %w", err)
	}
	return &client{socket: socket, token: strings.TrimSpace(string(secret))}, nil
}

type response struct {
	OK     bool   `json:"ok"`
	Code   string `json:"code"`
	Result struct {
		Payload json.RawMessage `json:"payload"`
	} `json:"result"`
}

// request sends one request and returns the payload of its result. A request that changes
// nothing (no_change, e.g. moving a window to its own workspace) succeeds, as do the error
// codes in okCodes.
func (c *client) request(kind, name string, fields map[string]any, okCodes ...string) (json.RawMessage, error) {
	payload := map[string]any{"name": name}
	maps.Copy(payload, fields)
	c.sent++
	body, err := json.Marshal(map[string]any{
		"authorizationToken": c.token,
		"id":                 strconv.Itoa(c.sent),
		"kind":               kind,
		"payload":            payload,
		"version":            protocolVersion,
	})
	if err != nil {
		return nil, err
	}

	conn, err := net.Dial("unix", c.socket)
	if err != nil {
		return nil, fmt.Errorf("cannot reach OmniWM (is it running with IPC on?): %w", err)
	}
	defer conn.Close()
	if _, err := conn.Write(append(body, '\n')); err != nil {
		return nil, fmt.Errorf("%s %s: %w", kind, name, err)
	}
	line, err := bufio.NewReader(conn).ReadBytes('\n')
	if err != nil {
		return nil, fmt.Errorf("%s %s: no response: %w", kind, name, err)
	}

	var resp response
	if err := json.Unmarshal(line, &resp); err != nil {
		return nil, fmt.Errorf("%s %s: unreadable response: %w", kind, name, err)
	}
	if !resp.OK && resp.Code != "no_change" && !slices.Contains(okCodes, resp.Code) {
		return nil, fmt.Errorf("%s %s: %s", kind, name, cmp.Or(resp.Code, "failed"))
	}
	return resp.Result.Payload, nil
}
