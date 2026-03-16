const std = @import("std");
const chip_8_zig = @import("chip_8_zig");

pub fn main() !void {
    var memory: [4096]u8 = undefined;
    var display: [64][32]bool = .{.{false} ** 32} ** 64;
    var stack: [16]u16 = undefined;
    var stack_ptr: u8 = 0;
    var delay_timer: u8 = 0;
    var sound_timer: u8 = 0;
    var pc: u8 = 0;
    var registers: [16]u8 = undefined;

    // store font data
    var font_item = [_]u8{
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80  // F
    };
    @memcpy(memory[80..160], &font_item);

    delay_timer = 0;
    sound_timer = 0;

    while (true) {
        //fetch
        var i: u16 = @as(u16, @intCast(memory[pc])) << 8 | @as(u16, @intCast(memory[pc+1]));
        pc += 2;

        // decode & execute
        const kind: u16 = i & 0xF000;
        const x: u16 = i & 0x0F00;
        const y: u16 = i & 0x00F0;
        const n: u16 = i & 0x000F;
        const nn: u16 = i & 0x00FF;
        const nnn: u16 = i & 0x0FFF;

        const result = switch (kind) {
            0x0 => switch (nnn) {
                // clear screen
                0x0E0 => display = .{.{false} ** 32} ** 64,
                // return from subroutine
                0x0EE => {
                    if (stack_ptr <= 0) {}
                    pc = stack[stack_ptr];
                    stack[stack_ptr] = 0;
                    stack_ptr -= 1;
                },
                else => 0,
            },

            // jump
            0x1 => pc = nnn,

            // call subroutine
            0x2 => {
                stack[stack_ptr] = pc;
                pc = nnn;
            },
            0x3 => if (nn == registers[x]) { pc += 2; },
            0x4 => if (nn != registers[x]) { pc += 2; },
            0x5 => if (x == y) { pc += 2; },
            0x6 => registers[x] == nn,
            0x7 => registers[x] += nn,
            0x8 => switch (n) {
                0x0 => registers[x] = registers[y],
                0x1 => registers[x] = registers[x] | registers[y],
                0x2 => registers[x] = registers[x] & registers[y],
                0x3 => registers[x] = registers[x] ^ registers[y],
                0x4 => registers[x] = registers[x] + registers[y],
                0x5 => registers[x] = registers[x] - registers[y],
                0x6 => registers[x] = registers[x] >> 1,
                0x7 => registers[x] = registers[y] - registers[x],
                0xD => registers[x] = registers[x] << 1,
                else => 0,
            },
            0x9 => if (x != y) { pc += 2; },
            0xA => i = nnn,
            0xB => pc = nnn + registers[0],
            0xC => {
                var prng = std.Random.DefaultPrng();
                const rand = prng.random();
                rand.intRangeAtMost(u8, 0, 255) & nn;
            },
            0xD => 0,
            0xE => 0,
            0xF => 0,
            else => 1,
        };

        _ = result;

        // execute
    }
}
