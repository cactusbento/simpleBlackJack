const std = @import("std");
const rg = @import("raygui");
const rl = @import("raylib");

const globals = @import("main.zig").globals;

pub const Card = @import("card.zig");
pub const Hand = @import("hand.zig");

pub const FiniteStateMachine = struct {
    var rng: std.rand.DefaultPrng = undefined;

    pub const GameState = enum {
        game_start,
        player_plays,
        dealer_plays,
        game_end,
    };

    allocator: std.mem.Allocator,

    state: GameState,
    player: Player,
    dealer: Dealer,

    pub fn init(allocator: std.mem.Allocator) FiniteStateMachine {
        rng = std.rand.DefaultPrng.init(@intCast(std.time.timestamp()));
        return .{
            .allocator = allocator,
            .state = .game_start,
            .player = Player.init(allocator),
            .dealer = Dealer.init(allocator),
        };
    }

    pub fn deinit(self: *FiniteStateMachine) void {
        self.player.deinit();
        self.dealer.deinit();
    }

    const buttons = struct {
        pub var hit = rg.elements.Button.init("Hit", .{ .x = 240, .width = 75 });
        pub var stand = rg.elements.Button.init("Stand", .{ .x = 240, .width = 75 });
    };

    pub fn update(self: *FiniteStateMachine) !void {
        switch (self.state) {
            .game_start => {
                // Reset all hands
                self.player.hand.cards.clearAndFree();
                self.dealer.hand.cards.clearAndFree();

                // Add 2 cards for dealer
                try self.dealer.hand.add(randomCard());
                try self.dealer.hand.add(randomCard());
                // Flip dealer's second card
                self.dealer.hand.cards.items[1].is_flipped = true;

                // Add 2 cards for player
                try self.player.hand.add(randomCard());
                try self.player.hand.add(randomCard());

                // Move onto the next state.
                self.state = .player_plays;
            },
            .player_plays => {
                defer self.player.draw();
                defer self.dealer.draw();

                buttons.hit.rect.y = self.player.hand.pos.y - 60;
                buttons.stand.rect.y = self.player.hand.pos.y - 100;

                const val = Value.count(self.player.hand);

                if (val.high == 21 or val.low == 21) {
                    self.state = .dealer_plays;
                }

                if (val.low <= 21) {
                    buttons.hit.draw();

                    if (buttons.hit.value) {
                        try self.player.hand.add(randomCard());
                    }
                } else {
                    // Player is BUST!
                    // Move on to next state.
                    self.state = .dealer_plays;
                    return;
                }

                buttons.stand.draw();
                if (buttons.stand.value) {
                    self.state = .dealer_plays;
                }
            },
            .dealer_plays => {
                defer self.player.draw();
                defer self.dealer.draw();

                for (self.dealer.hand.cards.items) |*c| {
                    if (c.is_flipped) {
                        c.is_flipped = false;
                        std.time.sleep(std.time.ns_per_ms * 750);
                        return;
                    }
                }

                const val = Value.count(self.dealer.hand);
                if (val.low < 17) {
                    std.time.sleep(std.time.ns_per_ms * 750);
                    try self.dealer.hand.add(randomCard());
                } else {
                    self.state = .game_end;
                }
            },
            .game_end => {
                defer self.player.draw();
                defer self.dealer.draw();
                std.time.sleep(std.time.ns_per_ms * 1500);

                self.state = .game_start;
            },
        }
    }

    fn randomCard() Card {
        rng.seed(rng.next());
        const rand = rng.random();

        const suit_ti: std.builtin.Type.Enum = @typeInfo(Card.Suit).Enum;
        const rank_ti: std.builtin.Type.Enum = @typeInfo(Card.Rank).Enum;

        const suit: Card.Suit = @enumFromInt(rand.uintAtMost(usize, suit_ti.fields.len - 1));
        const rank: Card.Rank = @enumFromInt(rand.uintAtMost(usize, rank_ti.fields.len - 1));

        return Card{ .suit = suit, .rank = rank };
    }
};

const Value = struct {
    low: u32,
    high: u32,

    pub fn count(hand: Hand) Value {
        var low: u32 = 0;
        var high: u32 = 0;

        for (hand.cards.items) |card| {
            if (card.is_flipped) continue;
            switch (card.rank) {
                .ace => {
                    low += 1;
                    high += if (high + 11 > 21) 1 else 11;
                },
                .two => {
                    low += 2;
                    high += 2;
                },
                .three => {
                    low += 3;
                    high += 3;
                },
                .four => {
                    low += 4;
                    high += 4;
                },
                .five => {
                    low += 5;
                    high += 5;
                },
                .six => {
                    low += 6;
                    high += 6;
                },
                .seven => {
                    low += 7;
                    high += 7;
                },
                .eight => {
                    low += 8;
                    high += 8;
                },
                .nine => {
                    low += 9;
                    high += 9;
                },
                .ten, .jack, .queen, .king => {
                    low += 10;
                    high += 10;
                },
            }
        }

        return .{
            .low = low,
            .high = high,
        };
    }
};

pub const Dealer = struct {
    allocator: std.mem.Allocator,

    hand: Hand,

    pub fn init(allocator: std.mem.Allocator) Dealer {
        return .{
            .allocator = allocator,
            .hand = Hand.init(allocator),
        };
    }

    pub fn deinit(self: *Dealer) void {
        self.hand.deinit();
    }

    pub fn draw(self: *Dealer) void {
        self.hand.pos = .{
            .x = @floatFromInt(@divTrunc(globals.window.width, 2)),
            .y = 20,
        };

        self.hand.draw();

        const count = Value.count(self.hand);
        var buf: [16]u8 = undefined;
        var val_str: [:0]const u8 = undefined;
        if (count.high <= 21) {
            val_str = std.fmt.bufPrintZ(&buf, "{d: >2}/{d: >2}", .{ count.low, count.high }) catch "??/??";
        } else {
            if (count.low <= 21) {
                val_str = std.fmt.bufPrintZ(&buf, "{d: >2}", .{count.low}) catch "??";
            } else {
                val_str = "Bust!";
            }
        }

        const text_len: f32 = @floatFromInt(rl.measureText(val_str, 20));
        const text_x: i32 = @intFromFloat(self.hand.pos.x - (text_len / 2));
        const text_y: i32 = @intFromFloat(self.hand.pos.y + Card.stdHeight + 20);

        rl.drawText(val_str, text_x, text_y, 20, if (count.low <= 21) rl.Color.black else rl.Color.red);
    }
};

pub const Player = struct {
    allocator: std.mem.Allocator,

    hand: Hand,

    pub fn init(allocator: std.mem.Allocator) Player {
        return .{
            .allocator = allocator,
            .hand = Hand.init(allocator),
        };
    }

    pub fn deinit(self: *Player) void {
        self.hand.deinit();
    }

    pub fn draw(self: *Player) void {
        const from_bottom: f32 = @floatFromInt(globals.window.height - 20);
        self.hand.pos = .{
            .x = @floatFromInt(@divTrunc(globals.window.width, 2)),
            .y = from_bottom - Card.stdHeight,
        };

        self.hand.draw();

        const count = Value.count(self.hand);
        var buf: [16]u8 = undefined;
        var val_str: [:0]const u8 = undefined;
        if (count.high <= 21) {
            val_str = std.fmt.bufPrintZ(&buf, "{d: >2}/{d: >2}", .{ count.low, count.high }) catch "??/??";
        } else {
            if (count.low <= 21) {
                val_str = std.fmt.bufPrintZ(&buf, "{d: >2}", .{count.low}) catch "??";
            } else {
                val_str = "Bust!";
            }
        }

        const text_len: f32 = @floatFromInt(rl.measureText(val_str, 20));
        const text_x: i32 = @intFromFloat(self.hand.pos.x - (text_len / 2));
        const text_y: i32 = @intFromFloat(self.hand.pos.y - 40);

        rl.drawText(val_str, text_x, text_y, 20, if (count.low <= 21) rl.Color.black else rl.Color.red);
    }
};
