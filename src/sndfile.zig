const std = @import("std");

pub const c = @cImport({
    @cInclude("sndfile.h");
});

pub const Mode = extern enum(c_int) {
    Read = c.SFM_READ,
    Write = c.SFM_WRITE,
    ReadWrite = c.SFM_RDWR,
};

pub const Info = extern struct {
    frames: i64,
    samplerate: c_int,
    channels: c_int,
    format: c_int,
    sections: c_int,
    seekable: c_int,
};

const Format = extern enum(c_int) {
    WAV = c.SF_FORMAT_WAV,
    AIFF = c.SF_FORMAT_AIFF,
    AU = c.SF_FORMAT_AU,
    RAW = c.SF_FORMAT_RAW,
    PAF = c.SF_FORMAT_PAF,
    SVX = c.SF_FORMAT_SVX,
    NIST = c.SF_FORMAT_NIST,
    VOC = c.SF_FORMAT_VOC,
    IRCAM = c.SF_FORMAT_IRCAM,
    W64 = c.SF_FORMAT_W64,
    MAT4 = c.SF_FORMAT_MAT4,
    MAT5 = c.SF_FORMAT_MAT5,
    PVF = c.SF_FORMAT_PVF,
    XI = c.SF_FORMAT_XI,
    HTK = c.SF_FORMAT_HTK,
    SDS = c.SF_FORMAT_SDS,
    AVR = c.SF_FORMAT_AVR,
    WAVEX = c.SF_FORMAT_WAVEX,
    SD2 = c.SF_FORMAT_SD2,
    FLAC = c.SF_FORMAT_FLAC,
    CAF = c.SF_FORMAT_CAF,
    WVE = c.SF_FORMAT_WVE,
    OGG = c.SF_FORMAT_OGG,
    MPC2K = c.SF_FORMAT_MPC2K,
    RF64 = c.SF_FORMAT_RF64,
    PCM_S8 = c.SF_FORMAT_PCM_S8,
    PCM_16 = c.SF_FORMAT_PCM_16,
    PCM_24 = c.SF_FORMAT_PCM_24,
    PCM_32 = c.SF_FORMAT_PCM_32,
    PCM_U8 = c.SF_FORMAT_PCM_U8,
    FLOAT = c.SF_FORMAT_FLOAT,
    DOUBLE = c.SF_FORMAT_DOUBLE,
    ULAW = c.SF_FORMAT_ULAW,
    ALAW = c.SF_FORMAT_ALAW,
    IMA_ADPCM = c.SF_FORMAT_IMA_ADPCM,
    MS_ADPCM = c.SF_FORMAT_MS_ADPCM,
    GSM610 = c.SF_FORMAT_GSM610,
    VOX_ADPCM = c.SF_FORMAT_VOX_ADPCM,
    G721_32 = c.SF_FORMAT_G721_32,
    G723_24 = c.SF_FORMAT_G723_24,
    G723_40 = c.SF_FORMAT_G723_40,
    DWVW_12 = c.SF_FORMAT_DWVW_12,
    DWVW_16 = c.SF_FORMAT_DWVW_16,
    DWVW_24 = c.SF_FORMAT_DWVW_24,
    DWVW_N = c.SF_FORMAT_DWVW_N,
    DPCM_8 = c.SF_FORMAT_DPCM_8,
    DPCM_16 = c.SF_FORMAT_DPCM_16,
    VORBIS = c.SF_FORMAT_VORBIS,
    ALAC_16 = c.SF_FORMAT_ALAC_16,
    ALAC_20 = c.SF_FORMAT_ALAC_20,
    ALAC_24 = c.SF_FORMAT_ALAC_24,
    ALAC_32 = c.SF_FORMAT_ALAC_32,
    _,
    SUBMASK = c.SF_FORMAT_SUBMASK,
    TYPEMASK = c.SF_FORMAT_TYPEMASK,
    ENDMASK = c.SF_FORMAT_ENDMASK,
    _,
};

pub const Endian = extern enum(c_uint) {
    FILE = c.SF_ENDIAN_FILE,
    LITTLE = c.SF_ENDIAN_LITTLE,
    BIG = c.SF_ENDIAN_BIG,
    CPU = c.SF_ENDIAN_CPU,
};

pub const SoundFile = struct {
    allocator: *std.mem.Allocator,
    handle: *c.SNDFILE,
    info: *Info,

    const Self = @This();

    pub fn open(
        allocator: *std.mem.Allocator,
        path: []const u8,
        mode: Mode,
        info: *Info,
    ) !Self {
        var cstr_path = try std.cstr.addNullByte(allocator, path);
        defer allocator.free(cstr_path);

        var file = c.sf_open(
            cstr_path.ptr,
            @enumToInt(mode),
            @ptrCast(*c.SF_INFO, info),
        );

        const status = c.sf_error(file);
        if (status != 0) {
            const err = std.mem.spanZ(c.sf_error_number(status));
            std.debug.warn("Failed to open {} ({})\n", .{
                path, err,
            });

            return error.OpenFail;
        }

        // assert that frame information matches up before using the file
        const frames_on_end = c.sf_seek(file, 0, c.SEEK_END);
        _ = c.sf_seek(file, 0, c.SEEK_SET);
        std.testing.expectEqual(info.frames, frames_on_end);

        const frames_on_end_by_end = c.sf_seek(file, frames_on_end, c.SEEK_SET);
        std.testing.expectEqual(frames_on_end, frames_on_end_by_end);

        _ = c.sf_seek(file, 0, c.SEEK_SET);
        return SoundFile{
            .allocator = allocator,
            .handle = file.?,
            .info = info,
        };
    }

    pub fn close(self: Self) void {
        _ = c.sf_close(self.handle);
    }

    // Will read N frames per N channel. be sure buf has enough size.
    pub fn read(self: Self, buf: []f64) usize {
        return @intCast(usize, c.sf_readf_double(self.handle, buf.ptr, @intCast(i64, buf.len)));
    }
};
