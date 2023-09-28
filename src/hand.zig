const std = @import("std");
const rg = @import("raygui");
const rl = @import("raylib");

const Card = @import("card.zig");
const Hand = @This();

allocator: std.mem.Allocator,

cards: std.ArrayList(Card),

spacing: f32 = 30,

/// This denotes the top center of the hand.
pos: rl.Vector2 = .{
    .x = 0,
    .y = 0,
},

pub fn init(allocator: std.mem.Allocator) Hand {
    return .{
        .allocator = allocator,
        .cards = std.ArrayList(Card).init(allocator),
    };
}

pub fn deinit(self: *Hand) void {
    self.cards.deinit();
}

pub fn add(self: *Hand, card: Card) !void {
    // Ensure that the inserted card is mutable.
    var tmp: Card = card;
    try self.cards.append(tmp);
}

pub fn draw(self: *Hand) void {
    const x_offset = self.getWidth() / 2;
    const left_edge = self.pos.x - x_offset;

    for (self.cards.items, 0..) |*card, i| {
        const f: f32 = @floatFromInt(i);

        card.pos.y = self.pos.y;
        card.pos.x = left_edge + self.spacing * f;

        card.draw();
    }
}

pub fn getWidth(self: *Hand) f32 {
    const width: f32 = Card.stdWidth;

    const len: f32 = @floatFromInt(self.cards.items.len);
    var additional: f32 = self.spacing * len;

    return width + additional;
}
