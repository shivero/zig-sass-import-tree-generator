const std = @import("std");
const expect = std.testing.expect;

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    std.log.info("Flux capacitor is starting to overheat {d}", .{5});

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    var file = try std.fs.cwd().openFile("/home/grzes/repos/zig-hello/src/example.scss", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // do something with line...
        std.log.debug("Bytes read: {s}", .{line});

        const import_text = "@import";
        // var inner_file = try std.fs.cwd().openFile("/home/grzes/repos/zig-hello/src/example.scss", .{});
        if (std.mem.indexOf(u8, line, import_text)) |index| {
            std.log.info("Found import: {s} at index {}", .{ line, index });
            const first_quote_index = std.mem.indexOf(u8, line, "\"");
            if (first_quote_index != 0 and first_quote_index != undefined) {
                std.log.info("Znaleziono pierwszy quote na pozycji: {?d}", .{first_quote_index});
                std.log.info("szukamy teraz drugiego quote w ciagu {s}", .{line[first_quote_index.? + 1 ..]});
                const second_quote_index = std.mem.indexOf(u8, line[first_quote_index.? + 1 ..], "\"");
                if (second_quote_index != 0 or second_quote_index != undefined) {
                    std.log.info("Znaleziono drugi quote na pozycji : {?d}", .{second_quote_index});
                    const secon = first_quote_index.? + 1 + second_quote_index.?;
                    const pathToNestedFile = line[first_quote_index.? + 1 .. secon];
                    std.log.info("zagnieżdżony plik do przeszukania: {s}", .{pathToNestedFile});
                    const basePath = "/home/grzes/repos/zig-hello/src";
                    const result = try TryOpenFile(basePath, pathToNestedFile[2..]);
                    std.log.info("zagnieżdżony plik do przeszukania: {any}", .{result});
                }
            }
        } else {}
    }
    try bw.flush(); // don't forget to flush!
}

pub fn TryOpenFile(basePath: []const u8, fileName: []u8) !void {
    std.log.info("TryOpenFile, basePath: {s}, fileName: {s}", .{ basePath, fileName });

    // bad, 4kb static
    const allocator = std.heap.page_allocator;

    const pathWithCwd = try std.fmt.allocPrint(allocator, "{s}/{s}.scss", .{ basePath, fileName });
    defer allocator.free(pathWithCwd);
    if (std.fs.cwd().openFile(pathWithCwd, .{})) |nestedFile| {
        // doSomethingWithNumber(number);
        defer nestedFile.close();
        var buf_reader2 = std.io.bufferedReader(nestedFile.reader());
        var in_stream2 = buf_reader2.reader();
        var buf2: [1024]u8 = undefined;
        while (try in_stream2.readUntilDelimiterOrEof(&buf2, '\n')) |line2| {
            std.log.info("zawartość pliku '{s}'', linia: {s}", .{ fileName, line2 });
        }
    } else |err| switch (err) {
        error.FileNotFound => {
            std.log.info("File not Found at path:, {s}", .{pathWithCwd});
            const underscored = try std.fmt.allocPrint(allocator, "_{s}", .{fileName});
            try TryOpenFile(basePath, underscored);
        },
        else => |leftover_err| return leftover_err,
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
