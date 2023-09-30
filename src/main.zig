const std = @import("std");
const rg = @import("raygui");
const rl = @import("raylib");

const game = @import("game.zig");

pub const globals = struct {
    pub const window = struct {
        pub var width: i32 = 1280;
        pub var height: i32 = 720;
    };
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    rl.setConfigFlags(.flag_window_resizable);
    rl.initWindow(1280, 720, "Hello World");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var game_state = try game.FiniteStateMachine.init(allocator);
    defer game_state.deinit();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        globals.window.width = rl.getScreenWidth();
        globals.window.height = rl.getScreenHeight();

        rl.clearBackground(rl.Color.ray_white);

        try game_state.update();
    }
}
