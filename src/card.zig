const std = @import("std");
const rg = @import("raygui");
const rl = @import("raylib");

const Card = @This();

pub const stdWidth: f32 = 120;
pub const stdHeight: f32 = 180;

pos: rl.Vector2 = .{ .x = 0, .y = 0 },
scale: f32 = 1.0,

suit: Suit,
rank: Rank,

is_flipped: bool = false,

pub const Suit = enum {
    clubs,
    spades,
    hearts,
    diamonds,

    const colorMap = blk: {
        var cm = std.EnumMap(Suit, rl.Color){};
        cm.put(.spades, rl.Color.black);
        cm.put(.clubs, rl.Color.black);
        cm.put(.diamonds, rl.Color.red);
        cm.put(.hearts, rl.Color.red);
        break :blk cm;
    };

    pub fn color(self: *Suit) rl.Color {
        return colorMap.getAssertContains(self.*);
    }
};
pub const Rank = enum { ace, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king };

pub fn draw(self: *Card) void {
    // The border
    rl.drawRectangleV(self.pos, .{
        .x = stdWidth * self.scale,
        .y = stdHeight * self.scale,
    }, rl.Color.gray);

    // Inner face (Flipped)
    if (self.is_flipped) {
        rl.drawRectangleV(.{
            .x = self.pos.x + 2,
            .y = self.pos.y + 2,
        }, .{
            .x = (stdWidth - 4) * self.scale,
            .y = (stdHeight - 4) * self.scale,
        }, rl.Color.dark_purple);
        return;
    }

    // Inner face (UnFlipped)
    rl.drawRectangleV(.{
        .x = self.pos.x + 2,
        .y = self.pos.y + 2,
    }, .{
        .x = (stdWidth - 4) * self.scale,
        .y = (stdHeight - 4) * self.scale,
    }, rl.Color.ray_white);

    var buf_rank: [8:0]u8 = undefined;

    const rank_str = std.fmt.bufPrintZ(&buf_rank, "{s}", .{
        switch (self.rank) {
            .ace => "A",
            .two => "2",
            .three => "3",
            .four => "4",
            .five => "5",
            .six => "6",
            .seven => "7",
            .eight => "8",
            .nine => "9",
            .ten => "10",
            .jack => "J",
            .queen => "Q",
            .king => "K",
        },
    }) catch "??";

    var buf_suit: [8:0]u8 = undefined;

    const suit_str = std.fmt.bufPrintZ(&buf_suit, "{s}", .{
        switch (self.suit) {
            .clubs => "C",
            .diamonds => "D",
            .hearts => "H",
            .spades => "S",
        },
    }) catch "?";

    rl.drawText(rank_str, @intFromFloat(self.pos.x + 4), @intFromFloat(self.pos.y + 4), 20, self.suit.color());
    rl.drawText(suit_str, @intFromFloat(self.pos.x + 4), @intFromFloat(self.pos.y + 24), 20, self.suit.color());

    const font = rl.getFontDefault();

    rl.drawTextPro(font, rank_str, .{
        .x = self.pos.x + (stdWidth - 4) * self.scale,
        .y = self.pos.y + (stdHeight - 4) * self.scale,
    }, .{ .x = 0, .y = 0 }, 180, 20, 0, self.suit.color());

    rl.drawTextPro(font, suit_str, .{
        .x = self.pos.x + (stdWidth - 4) * self.scale,
        .y = self.pos.y + (stdHeight - 24) * self.scale,
    }, .{ .x = 0, .y = 0 }, 180, 20, 0, self.suit.color());
}
