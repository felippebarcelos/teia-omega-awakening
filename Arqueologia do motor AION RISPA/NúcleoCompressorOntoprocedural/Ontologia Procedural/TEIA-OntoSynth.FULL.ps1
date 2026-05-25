# TEIA-OntoSynth.ps1 — Autocontido · Idempotente
param(
  [string]$OutDir = "$PSScriptRoot",
  [switch]$WriteJson,
  [switch]$PrintSummary
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::UTF8

# JSON sintetizado embutido (gerado automaticamente)
$synthJson = @'
{
  "synth_version": "onto-synth.v1",
  "generated_utc": "2025-09-25T15:26:50.203823Z",
  "source_zip": "/mnt/data/Ontology.zip",
  "stats": {
    "total_files_in_zip": 152,
    "unique_hashes": 80,
    "unique_non_mac": 22,
    "duplicates_groups": 38,
    "duplicates_files": 72,
    "ext_distribution_unique_non_mac": {
      ".json": 60,
      ".ps1": 17,
      ".py": 1,
      ".pyc": 2
    }
  },
  "base_ontology": {
    "version": "1.0",
    "updated_utc": "2025-09-13T19:07:15Z",
    "notes": "Baseline ontology. Extend by appending formats; no payload definitions.",
    "categories": {
      "text": {
        "mime": [
          "text/plain",
          "text/markdown",
          "text/csv",
          "text/html",
          "text/xml",
          "application/json",
          "application/x-yaml",
          "application/toml"
        ],
        "extensions": [
          ".txt",
          ".md",
          ".csv",
          ".html",
          ".htm",
          ".xml",
          ".json",
          ".yaml",
          ".yml",
          ".toml",
          ".ini",
          ".log"
        ]
      },
      "image_raster": {
        "mime": [
          "image/png",
          "image/jpeg",
          "image/gif",
          "image/bmp",
          "image/webp",
          "image/tiff",
          "image/x-icon",
          "image/heic",
          "image/heif"
        ],
        "extensions": [
          ".png",
          ".jpg",
          ".jpeg",
          ".gif",
          ".bmp",
          ".webp",
          ".tif",
          ".tiff",
          ".ico",
          ".heic",
          ".heif"
        ]
      },
      "image_vector": {
        "mime": [
          "image/svg+xml",
          "application/pdf"
        ],
        "extensions": [
          ".svg",
          ".pdf"
        ]
      },
      "audio": {
        "mime": [
          "audio/wav",
          "audio/x-wav",
          "audio/mpeg",
          "audio/mp4",
          "audio/aac",
          "audio/ogg",
          "audio/flac",
          "audio/opus",
          "audio/webm"
        ],
        "extensions": [
          ".wav",
          ".mp3",
          ".m4a",
          ".aac",
          ".oga",
          ".ogg",
          ".flac",
          ".opus",
          ".weba"
        ]
      },
      "video": {
        "mime": [
          "video/mp4",
          "video/x-msvideo",
          "video/x-matroska",
          "video/webm",
          "video/quicktime",
          "video/mpeg"
        ],
        "extensions": [
          ".mp4",
          ".avi",
          ".mkv",
          ".webm",
          ".mov",
          ".mpg",
          ".mpeg"
        ]
      },
      "archive": {
        "mime": [
          "application/zip",
          "application/x-7z-compressed",
          "application/x-rar-compressed",
          "application/x-tar",
          "application/gzip",
          "application/x-bzip2",
          "application/x-xz"
        ],
        "extensions": [
          ".zip",
          ".7z",
          ".rar",
          ".tar",
          ".gz",
          ".tgz",
          ".bz2",
          ".xz"
        ]
      },
      "documents": {
        "mime": [
          "application/pdf",
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
          "application/msword",
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          "application/vnd.ms-excel",
          "application/vnd.openxmlformats-officedocument.presentationml.presentation",
          "application/vnd.ms-powerpoint"
        ],
        "extensions": [
          ".pdf",
          ".docx",
          ".doc",
          ".xlsx",
          ".xls",
          ".pptx",
          ".ppt",
          ".rtf",
          ".odt",
          ".ods",
          ".odp"
        ]
      },
      "executables": {
        "mime": [
          "application/x-dosexec",
          "application/vnd.microsoft.portable-executable",
          "application/x-msdownload"
        ],
        "extensions": [
          ".exe",
          ".dll",
          ".sys",
          ".ocx"
        ]
      },
      "libraries_objects": {
        "mime": [
          "application/x-elf",
          "application/x-archive",
          "application/x-object"
        ],
        "extensions": [
          ".so",
          ".a",
          ".o",
          ".elf"
        ]
      },
      "database": {
        "mime": [
          "application/x-sqlite3",
          "application/vnd.ms-access",
          "application/x-paradox",
          "application/x-dbf"
        ],
        "extensions": [
          ".sqlite",
          ".db",
          ".mdb",
          ".accdb",
          ".dbf"
        ]
      },
      "disk_images": {
        "mime": [
          "application/x-iso9660-image",
          "application/x-raw-disk-image"
        ],
        "extensions": [
          ".iso",
          ".img",
          ".vhd",
          ".vhdx"
        ]
      },
      "fonts": {
        "mime": [
          "font/ttf",
          "font/otf",
          "application/vnd.ms-fontobject",
          "font/woff",
          "font/woff2"
        ],
        "extensions": [
          ".ttf",
          ".otf",
          ".eot",
          ".woff",
          ".woff2"
        ]
      },
      "3d": {
        "mime": [
          "model/obj",
          "model/stl",
          "model/3mf",
          "model/gltf+json",
          "model/gltf-binary"
        ],
        "extensions": [
          ".obj",
          ".stl",
          ".3mf",
          ".gltf",
          ".glb",
          ".fbx"
        ]
      },
      "geospatial": {
        "mime": [
          "application/vnd.google-earth.kml+xml",
          "application/vnd.google-earth.kmz",
          "application/octet-stream"
        ],
        "extensions": [
          ".kml",
          ".kmz",
          ".shp",
          ".geojson",
          ".tif"
        ]
      },
      "web": {
        "mime": [
          "application/javascript",
          "text/css"
        ],
        "extensions": [
          ".js",
          ".mjs",
          ".css"
        ]
      },
      "code": {
        "mime": [
          "text/x-python",
          "text/x-c",
          "text/x-c++",
          "text/x-java-source",
          "text/x-shellscript",
          "text/x-powershell",
          "text/x-go",
          "text/x-rustsrc"
        ],
        "extensions": [
          ".py",
          ".c",
          ".h",
          ".cpp",
          ".hpp",
          ".cc",
          ".java",
          ".ps1",
          ".psm1",
          ".sh",
          ".bat",
          ".cmd",
          ".go",
          ".rs"
        ]
      },
      "config_data": {
        "mime": [
          "application/x-protobuf",
          "application/octet-stream",
          "application/x-msgpack"
        ],
        "extensions": [
          ".proto",
          ".bin",
          ".dat",
          ".msgpack",
          ".mpk"
        ]
      }
    },
    "magic_signatures": [
      {
        "name": "png",
        "offset": 0,
        "hex": "89504E470D0A1A0A",
        "mime": "image/png",
        "ext": [
          ".png"
        ]
      },
      {
        "name": "jpg",
        "offset": 0,
        "hex": "FFD8FF",
        "mime": "image/jpeg",
        "ext": [
          ".jpg",
          ".jpeg"
        ]
      },
      {
        "name": "gif87a",
        "offset": 0,
        "hex": "474946383761",
        "mime": "image/gif",
        "ext": [
          ".gif"
        ]
      },
      {
        "name": "gif89a",
        "offset": 0,
        "hex": "474946383961",
        "mime": "image/gif",
        "ext": [
          ".gif"
        ]
      },
      {
        "name": "bmp",
        "offset": 0,
        "hex": "424D",
        "mime": "image/bmp",
        "ext": [
          ".bmp"
        ]
      },
      {
        "name": "webp",
        "offset": 0,
        "hex": "52494646????57454250",
        "mime": "image/webp",
        "ext": [
          ".webp"
        ]
      },
      {
        "name": "pdf",
        "offset": 0,
        "hex": "25504446",
        "mime": "application/pdf",
        "ext": [
          ".pdf"
        ]
      },
      {
        "name": "zip",
        "offset": 0,
        "hex": "504B0304",
        "mime": "application/zip",
        "ext": [
          ".zip",
          ".jar",
          ".docx",
          ".xlsx",
          ".pptx"
        ]
      },
      {
        "name": "rar",
        "offset": 0,
        "hex": "526172211A0700",
        "mime": "application/x-rar-compressed",
        "ext": [
          ".rar"
        ]
      },
      {
        "name": "7z",
        "offset": 0,
        "hex": "377ABCAF271C",
        "mime": "application/x-7z-compressed",
        "ext": [
          ".7z"
        ]
      },
      {
        "name": "gz",
        "offset": 0,
        "hex": "1F8B08",
        "mime": "application/gzip",
        "ext": [
          ".gz",
          ".tgz"
        ]
      },
      {
        "name": "xz",
        "offset": 0,
        "hex": "FD377A585A00",
        "mime": "application/x-xz",
        "ext": [
          ".xz"
        ]
      },
      {
        "name": "wav",
        "offset": 0,
        "hex": "52494646????57415645",
        "mime": "audio/wav",
        "ext": [
          ".wav"
        ]
      },
      {
        "name": "avi",
        "offset": 0,
        "hex": "52494646????41564920",
        "mime": "video/x-msvideo",
        "ext": [
          ".avi"
        ]
      },
      {
        "name": "mp3_id3",
        "offset": 0,
        "hex": "494433",
        "mime": "audio/mpeg",
        "ext": [
          ".mp3"
        ]
      },
      {
        "name": "mp3_mpeg",
        "offset": 0,
        "hex": "FFFB",
        "mime": "audio/mpeg",
        "ext": [
          ".mp3"
        ]
      },
      {
        "name": "mp4",
        "offset": 4,
        "hex": "66747970",
        "mime": "video/mp4",
        "ext": [
          ".mp4",
          ".m4a",
          ".m4v"
        ]
      },
      {
        "name": "mov",
        "offset": 4,
        "hex": "6674797071742020",
        "mime": "video/quicktime",
        "ext": [
          ".mov"
        ]
      },
      {
        "name": "mkv",
        "offset": 0,
        "hex": "1A45DFA3",
        "mime": "video/x-matroska",
        "ext": [
          ".mkv"
        ]
      },
      {
        "name": "ico",
        "offset": 0,
        "hex": "00000100",
        "mime": "image/x-icon",
        "ext": [
          ".ico"
        ]
      },
      {
        "name": "exe_mz",
        "offset": 0,
        "hex": "4D5A",
        "mime": "application/x-dosexec",
        "ext": [
          ".exe",
          ".dll",
          ".sys"
        ]
      },
      {
        "name": "elf",
        "offset": 0,
        "hex": "7F454C46",
        "mime": "application/x-elf",
        "ext": [
          ".elf"
        ]
      },
      {
        "name": "sqlite",
        "offset": 0,
        "hex": "53514C69746520666F726D6174203300",
        "mime": "application/x-sqlite3",
        "ext": [
          ".sqlite",
          ".db"
        ]
      }
    ]
  },
  "seeds": [
    {
      "file": "Ontology/teia_format_ontology_1500e7a56cbc.seed (1).json",
      "sha256": "57cff3d38f26ccea1d1ee1953bb905e84d66f6f260f2eaa438d00130f14dbb4a",
      "size": 616,
      "fields": [
        "version",
        "created_utc",
        "file",
        "size",
        "sha256",
        "mtime_utc",
        "format",
        "generator",
        "procedural",
        "notes"
      ],
      "format": {
        "by": "magic",
        "ext": ".json",
        "mime": "image/png",
        "sig": "png"
      },
      "generator": {
        "name": "none",
        "params": {}
      },
      "procedural": false,
      "sha256_declared": "1500e7a56cbc30eddf103c1d77738f1ec6bdd66cea28909231dfb86bd7e23f16"
    },
    {
      "file": "Ontology/TEIA-OntoSeed-Gen.LowRAM_e68827162455.seed (2).json",
      "sha256": "d0c14a256b9baf0d8fdc4fa2b0b4ed57d94fd276787e859e49d06bef7f0288cc",
      "size": 616,
      "fields": [
        "version",
        "created_utc",
        "file",
        "size",
        "sha256",
        "mtime_utc",
        "format",
        "generator",
        "procedural",
        "notes"
      ],
      "format": {
        "sig": "png",
        "by": "magic",
        "ext": ".ps1",
        "mime": "image/png"
      },
      "generator": {
        "params": {},
        "name": "none"
      },
      "procedural": false,
      "sha256_declared": "e68827162455d01cafaf6d1a0fb69cb78499dbb9248d4d07c47112065dd01d88"
    },
    {
      "file": "Ontology/teia_format_ontology_1500e7a56cbc.seed_57cff3d38f26.seed_c02101ba555b.seed (2).json",
      "sha256": "62352263dc132a8b36dde6d402661d35c8a204da8f36cf3efb8f028223ebfcdd",
      "size": 653,
      "fields": [
        "version",
        "created_utc",
        "file",
        "size",
        "sha256",
        "mtime_utc",
        "format",
        "generator",
        "procedural",
        "notes"
      ],
      "format": {
        "sig": "png",
        "by": "magic",
        "ext": ".json",
        "mime": "image/png"
      },
      "generator": {
        "params": {},
        "name": "none"
      },
      "procedural": false,
      "sha256_declared": "c02101ba555bcb371b5cb7d2aa202ee7f317f2737ce7cb0e7b5980fae3d5f2cf"
    },
    {
      "file": "Ontology/TEIA-OntoEngine-Restore_e6b5626227b0.seed.json",
      "sha256": "e0e68d98bb6c65b64739c00720e3f02ee93d8bf687a96a6af2d09630664e5b93",
      "size": 615,
      "fields": [
        "version",
        "created_utc",
        "file",
        "size",
        "sha256",
        "mtime_utc",
        "format",
        "generator",
        "procedural",
        "notes"
      ],
      "format": {
        "sig": "png",
        "by": "magic",
        "ext": ".ps1",
        "mime": "image/png"
      },
      "generator": {
        "params": {},
        "name": "none"
      },
      "procedural": false,
      "sha256_declared": "e6b5626227b015c1f6c0de3f800e07444f8fc3c476d3732ea4014a05f881d0f8"
    },
    {
      "file": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed_614a77a8e5b5.seed.json",
      "sha256": "d295a489976ec15e473a4ac5c6185e0145c0f65a2bf958c134c9222a9429470b",
      "size": 632,
      "fields": [
        "version",
        "created_utc",
        "file",
        "size",
        "sha256",
        "mtime_utc",
        "format",
        "generator",
        "procedural",
        "notes"
      ],
      "format": {
        "ext": ".json",
        "by": "magic",
        "mime": "image/png",
        "sig": "png"
      },
      "generator": {
        "params": {},
        "name": "none"
      },
      "procedural": false,
      "sha256_declared": "614a77a8e5b5b8c0d0dae327719ac2626fd9429ba2c78f6de54469e0290adfbe"
    },
    {
      "file": "Ontology/TEIA-OntoEngine-Restore_e6b5626227b0.seed_cc74bc3922c4.seed (2).json",
      "sha256": "0c9eb3e4673d73e4bda4968d6e40ebd8cb1b2df1ead75951ffa3c5675167c995",
      "size": 638,
      "fields": [
        "version",
        "created_utc",
        "file",
        "size",
        "sha256",
        "mtime_utc",
        "format",
        "generator",
        "procedural",
        "notes"
      ],
      "format": {
        "ext": ".json",
        "by": "magic",
        "mime": "image/png",
        "sig": "png"
      },
      "generator": {
        "params": {},
        "name": "none"
      },
      "procedural": false,
      "sha256_declared": "cc74bc3922c4a7a19397a21ee0554524fa96ddc2ed87a9c53c92ef26b9126b5f"
    },
    {
      "file": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed.json",
      "sha256": "afdef4ba85fb6aa72fa9c9f5d6f0cd44fed939f98ea033c3736071439a9b3bfc",
      "size": 609,
      "fields": [
        "version",
        "created_utc",
        "file",
        "size",
        "sha256",
        "mtime_utc",
        "format",
        "generator",
        "procedural",
        "notes"
      ],
      "format": {
        "sig": "png",
        "by": "magic",
        "ext": ".ps1",
        "mime": "image/png"
      },
      "generator": {
        "params": {},
        "name": "none"
      },
      "procedural": false,
      "sha256_declared": "754c2e83b60d849a9414f910297ab3b1684cbb2017c868812810b1f257ed7a58"
    },
    {
      "file": "Ontology/teia_format_ontology_1b6d832c8c43.seed (3).json",
      "sha256": "285b0303c1f619e78c8ff990fb5aabd6ab81f136000327da32ff6ad7694f5c36",
      "size": 616,
      "fields": [
        "version",
        "created_utc",
        "file",
        "size",
        "sha256",
        "mtime_utc",
        "format",
        "generator",
        "procedural",
        "notes"
      ],
      "format": {
        "sig": "png",
        "by": "magic",
        "ext": ".json",
        "mime": "image/png"
      },
      "generator": {
        "params": {},
        "name": "none"
      },
      "procedural": false,
      "sha256_declared": "1b6d832c8c43951c3404aa19217f38f7d72ac84f60911642704b63e8b897f14b"
    },
    {
      "file": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed_6afba612ea1f.seed (1).json",
      "sha256": "38b76f50c66c0c4ca54f31da51d2fcfdf37699d81471bc27101678832683aa99",
      "size": 632,
      "fields": [
        "version",
        "created_utc",
        "file",
        "size",
        "sha256",
        "mtime_utc",
        "format",
        "generator",
        "procedural",
        "notes"
      ],
      "format": {
        "sig": "png",
        "by": "magic",
        "ext": ".json",
        "mime": "image/png"
      },
      "generator": {
        "params": {},
        "name": "none"
      },
      "procedural": false,
      "sha256_declared": "6afba612ea1fddc9b48790d375bbe1b07e5b4e2d4bb76acc15aa7937ba5958f9"
    },
    {
      "file": "Ontology/TEIA-OntoSeed-Gen.LowRAM_e68827162455.seed_09932f925941.seed.json",
      "sha256": "afa1aad9392e2860f09d87657ea8f78aff4f3ed85ff370e8c53fcbc2e62c8478",
      "size": 639,
      "fields": [
        "version",
        "created_utc",
        "file",
        "size",
        "sha256",
        "mtime_utc",
        "format",
        "generator",
        "procedural",
        "notes"
      ],
      "format": {
        "sig": "png",
        "by": "magic",
        "ext": ".json",
        "mime": "image/png"
      },
      "generator": {
        "params": {},
        "name": "none"
      },
      "procedural": false,
      "sha256_declared": "09932f9259416a0891a2dd744d1783e110a16a6ae392abaee4796b8a66d249c7"
    },
    {
      "file": "Ontology/teia_format_ontology_f58a3fe56681.seed_cc9771eb8d86.seed (1).json",
      "sha256": "9343fd43e124dc35dc7a16ee88bc59b36549e1bc7dc8945c626fe09b7218bb22",
      "size": 635,
      "fields": [
        "version",
        "created_utc",
        "file",
        "size",
        "sha256",
        "mtime_utc",
        "format",
        "generator",
        "procedural",
        "notes"
      ],
      "format": {
        "sig": "png",
        "by": "magic",
        "ext": ".json",
        "mime": "image/png"
      },
      "generator": {
        "params": {},
        "name": "none"
      },
      "procedural": false,
      "sha256_declared": "cc9771eb8d861d770daf368137e9c01159f15b7a401c3cb508803c73932e8f10"
    },
    {
      "file": "Ontology/teia_format_ontology_f58a3fe56681.seed (3).json",
      "sha256": "cc9771eb8d861d770daf368137e9c01159f15b7a401c3cb508803c73932e8f10",
      "size": 616,
      "fields": [
        "version",
        "created_utc",
        "file",
        "size",
        "sha256",
        "mtime_utc",
        "format",
        "generator",
        "procedural",
        "notes"
      ],
      "format": {
        "ext": ".json",
        "by": "magic",
        "mime": "image/png",
        "sig": "png"
      },
      "generator": {
        "params": {},
        "name": "none"
      },
      "procedural": false,
      "sha256_declared": "f58a3fe56681cc6efd37b03318a0f5e68cb35ebfa93cd8d31a3489500167d668"
    },
    {
      "file": "Ontology/TEIA-OntoEngine-Restore_e6b5626227b0.seed_cc74bc3922c4.seed_0c9eb3e4673d.seed (2).json",
      "sha256": "49d173fbc45bc77e59a1688b0e8306d3e93f2f7771a5bb4ee759a5ae1234ee39",
      "size": 656,
      "fields": [
        "version",
        "created_utc",
        "file",
        "size",
        "sha256",
        "mtime_utc",
        "format",
        "generator",
        "procedural",
        "notes"
      ],
      "format": {
        "sig": "png",
        "by": "magic",
        "ext": ".json",
        "mime": "image/png"
      },
      "generator": {
        "params": {},
        "name": "none"
      },
      "procedural": false,
      "sha256_declared": "0c9eb3e4673d73e4bda4968d6e40ebd8cb1b2df1ead75951ffa3c5675167c995"
    },
    {
      "file": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed_614a77a8e5b5.seed_d295a489976e.seed (2).json",
      "sha256": "29c7af7b8136917597909b91a9006264fd47cc569c5f743d54c8ba23e87744e5",
      "size": 650,
      "fields": [
        "version",
        "created_utc",
        "file",
        "size",
        "sha256",
        "mtime_utc",
        "format",
        "generator",
        "procedural",
        "notes"
      ],
      "format": {
        "sig": "png",
        "by": "magic",
        "ext": ".json",
        "mime": "image/png"
      },
      "generator": {
        "params": {},
        "name": "none"
      },
      "procedural": false,
      "sha256_declared": "d295a489976ec15e473a4ac5c6185e0145c0f65a2bf958c134c9222a9429470b"
    },
    {
      "file": "Ontology/TEIA-OntoEngine-Restore_e6b5626227b0.seed_42019f39afb7.seed (1).json",
      "sha256": "2607565b59369d5c5dfb896854b6c73a5e33862640482cdc851e8dae7a253f08",
      "size": 638,
      "fields": [
        "version",
        "created_utc",
        "file",
        "size",
        "sha256",
        "mtime_utc",
        "format",
        "generator",
        "procedural",
        "notes"
      ],
      "format": {
        "sig": "png",
        "by": "magic",
        "ext": ".json",
        "mime": "image/png"
      },
      "generator": {
        "params": {},
        "name": "none"
      },
      "procedural": false,
      "sha256_declared": "42019f39afb707a85b20358b1a2f340b9b7fd413843f8e653d6dbe5b0e5439ec"
    },
    {
      "file": "Ontology/teia_format_ontology_1500e7a56cbc.seed_57cff3d38f26.seed (1).json",
      "sha256": "8813abbb8f8036851c49e3939785884183589d54e3919f818e2ce02b5aa784b7",
      "size": 635,
      "fields": [
        "version",
        "created_utc",
        "file",
        "size",
        "sha256",
        "mtime_utc",
        "format",
        "generator",
        "procedural",
        "notes"
      ],
      "format": {
        "sig": "png",
        "by": "magic",
        "ext": ".json",
        "mime": "image/png"
      },
      "generator": {
        "params": {},
        "name": "none"
      },
      "procedural": false,
      "sha256_declared": "57cff3d38f26ccea1d1ee1953bb905e84d66f6f260f2eaa438d00130f14dbb4a"
    }
  ],
  "scripts_digest": [
    {
      "path": "Ontology/TEIA-OntoEngine-Restore.ps1",
      "size": 2580,
      "sha256": "e6b5626227b015c1f6c0de3f800e07444f8fc3c476d3732ea4014a05f881d0f8"
    },
    {
      "path": "Ontology/TEIA-OntoSeed-Gen (1).ps1",
      "size": 4978,
      "sha256": "754c2e83b60d849a9414f910297ab3b1684cbb2017c868812810b1f257ed7a58"
    },
    {
      "path": "Ontology/ontology.py",
      "size": 6174,
      "sha256": "a2936a25489a26b1d495f3833c72ae7f474eef4b4241c0da935c6fc4987d8aa5"
    }
  ],
  "duplicates": {
    "57cff3d38f26ccea1d1ee1953bb905e84d66f6f260f2eaa438d00130f14dbb4a": [
      {
        "path": "Ontology/teia_format_ontology_1500e7a56cbc.seed (1).json",
        "size": 616
      },
      {
        "path": "Ontology/teia_format_ontology_1500e7a56cbc.seed (3).json",
        "size": 616
      },
      {
        "path": "Ontology/teia_format_ontology_1500e7a56cbc.seed (2).json",
        "size": 616
      }
    ],
    "e6b5626227b015c1f6c0de3f800e07444f8fc3c476d3732ea4014a05f881d0f8": [
      {
        "path": "Ontology/TEIA-OntoEngine-Restore.ps1",
        "size": 2580
      },
      {
        "path": "Ontology/TEIA-OntoEngine-Restore__dedup_E6B56262 (2).ps1",
        "size": 2580
      },
      {
        "path": "Ontology/TEIA-OntoEngine-Restore (2).ps1",
        "size": 2580
      },
      {
        "path": "Ontology/TEIA-OntoEngine-Restore__dedup_E6B56262.ps1",
        "size": 2580
      },
      {
        "path": "Ontology/TEIA-OntoEngine-Restore (1).ps1",
        "size": 2580
      }
    ],
    "d0c14a256b9baf0d8fdc4fa2b0b4ed57d94fd276787e859e49d06bef7f0288cc": [
      {
        "path": "Ontology/TEIA-OntoSeed-Gen.LowRAM_e68827162455.seed (2).json",
        "size": 616
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen.LowRAM_e68827162455.seed (3).json",
        "size": 616
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen.LowRAM_e68827162455.seed (1).json",
        "size": 616
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen.LowRAM_e68827162455.seed.json",
        "size": 616
      }
    ],
    "e68827162455d01cafaf6d1a0fb69cb78499dbb9248d4d07c47112065dd01d88": [
      {
        "path": "Ontology/TEIA-OntoSeed-Gen.LowRAM__dedup_E6882716 (3).ps1",
        "size": 4270
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen.LowRAM__dedup_E6882716 (2).ps1",
        "size": 4270
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen.LowRAM (1).ps1",
        "size": 4270
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen.LowRAM__dedup_E6882716.ps1",
        "size": 4270
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen.LowRAM (2).ps1",
        "size": 4270
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen.LowRAM__dedup_E6882716 (1).ps1",
        "size": 4270
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen.LowRAM.ps1",
        "size": 4270
      }
    ],
    "62352263dc132a8b36dde6d402661d35c8a204da8f36cf3efb8f028223ebfcdd": [
      {
        "path": "Ontology/teia_format_ontology_1500e7a56cbc.seed_57cff3d38f26.seed_c02101ba555b.seed (2).json",
        "size": 653
      },
      {
        "path": "Ontology/teia_format_ontology_1500e7a56cbc.seed_57cff3d38f26.seed_c02101ba555b.seed (3).json",
        "size": 653
      },
      {
        "path": "Ontology/teia_format_ontology_1500e7a56cbc.seed_57cff3d38f26.seed_c02101ba555b.seed (1).json",
        "size": 653
      }
    ],
    "e0e68d98bb6c65b64739c00720e3f02ee93d8bf687a96a6af2d09630664e5b93": [
      {
        "path": "Ontology/TEIA-OntoEngine-Restore_e6b5626227b0.seed.json",
        "size": 615
      },
      {
        "path": "Ontology/TEIA-OntoEngine-Restore_e6b5626227b0.seed (2).json",
        "size": 615
      },
      {
        "path": "Ontology/TEIA-OntoEngine-Restore_e6b5626227b0.seed (1).json",
        "size": 615
      },
      {
        "path": "Ontology/TEIA-OntoEngine-Restore_e6b5626227b0.seed (3).json",
        "size": 615
      }
    ],
    "d295a489976ec15e473a4ac5c6185e0145c0f65a2bf958c134c9222a9429470b": [
      {
        "path": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed_614a77a8e5b5.seed.json",
        "size": 632
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed_614a77a8e5b5.seed (1).json",
        "size": 632
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed_614a77a8e5b5.seed (3).json",
        "size": 632
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed_614a77a8e5b5.seed (2).json",
        "size": 632
      }
    ],
    "0c9eb3e4673d73e4bda4968d6e40ebd8cb1b2df1ead75951ffa3c5675167c995": [
      {
        "path": "Ontology/TEIA-OntoEngine-Restore_e6b5626227b0.seed_cc74bc3922c4.seed (2).json",
        "size": 638
      },
      {
        "path": "Ontology/TEIA-OntoEngine-Restore_e6b5626227b0.seed_cc74bc3922c4.seed.json",
        "size": 638
      },
      {
        "path": "Ontology/TEIA-OntoEngine-Restore_e6b5626227b0.seed_cc74bc3922c4.seed (1).json",
        "size": 638
      }
    ],
    "afdef4ba85fb6aa72fa9c9f5d6f0cd44fed939f98ea033c3736071439a9b3bfc": [
      {
        "path": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed.json",
        "size": 609
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed (2).json",
        "size": 609
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed (1).json",
        "size": 609
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed (3).json",
        "size": 609
      }
    ],
    "285b0303c1f619e78c8ff990fb5aabd6ab81f136000327da32ff6ad7694f5c36": [
      {
        "path": "Ontology/teia_format_ontology_1b6d832c8c43.seed (3).json",
        "size": 616
      },
      {
        "path": "Ontology/teia_format_ontology_1b6d832c8c43.seed.json",
        "size": 616
      },
      {
        "path": "Ontology/teia_format_ontology_1b6d832c8c43.seed (2).json",
        "size": 616
      }
    ],
    "38b76f50c66c0c4ca54f31da51d2fcfdf37699d81471bc27101678832683aa99": [
      {
        "path": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed_6afba612ea1f.seed (1).json",
        "size": 632
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed_6afba612ea1f.seed (3).json",
        "size": 632
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed_6afba612ea1f.seed (2).json",
        "size": 632
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed_6afba612ea1f.seed.json",
        "size": 632
      }
    ],
    "1b6d832c8c43951c3404aa19217f38f7d72ac84f60911642704b63e8b897f14b": [
      {
        "path": "Ontology/teia_format_ontology (2).json",
        "size": 10152
      },
      {
        "path": "Ontology/teia_format_ontology.json",
        "size": 10152
      },
      {
        "path": "Ontology/teia_format_ontology (1).json",
        "size": 10152
      }
    ],
    "754c2e83b60d849a9414f910297ab3b1684cbb2017c868812810b1f257ed7a58": [
      {
        "path": "Ontology/TEIA-OntoSeed-Gen (1).ps1",
        "size": 4978
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen__dedup_754C2E83 (2).ps1",
        "size": 4978
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen__dedup_754C2E83.ps1",
        "size": 4978
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen__dedup_754C2E83 (3).ps1",
        "size": 4978
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen__dedup_754C2E83 (1).ps1",
        "size": 4978
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen.ps1",
        "size": 4978
      }
    ],
    "afa1aad9392e2860f09d87657ea8f78aff4f3ed85ff370e8c53fcbc2e62c8478": [
      {
        "path": "Ontology/TEIA-OntoSeed-Gen.LowRAM_e68827162455.seed_09932f925941.seed.json",
        "size": 639
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen.LowRAM_e68827162455.seed_09932f925941.seed (2).json",
        "size": 639
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen.LowRAM_e68827162455.seed_09932f925941.seed (3).json",
        "size": 639
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen.LowRAM_e68827162455.seed_09932f925941.seed (1).json",
        "size": 639
      }
    ],
    "9343fd43e124dc35dc7a16ee88bc59b36549e1bc7dc8945c626fe09b7218bb22": [
      {
        "path": "Ontology/teia_format_ontology_f58a3fe56681.seed_cc9771eb8d86.seed (1).json",
        "size": 635
      },
      {
        "path": "Ontology/teia_format_ontology_f58a3fe56681.seed_cc9771eb8d86.seed (3).json",
        "size": 635
      }
    ],
    "cc9771eb8d861d770daf368137e9c01159f15b7a401c3cb508803c73932e8f10": [
      {
        "path": "Ontology/teia_format_ontology_f58a3fe56681.seed (3).json",
        "size": 616
      },
      {
        "path": "Ontology/teia_format_ontology_f58a3fe56681.seed (1).json",
        "size": 616
      },
      {
        "path": "Ontology/teia_format_ontology_f58a3fe56681.seed (2).json",
        "size": 616
      }
    ],
    "49d173fbc45bc77e59a1688b0e8306d3e93f2f7771a5bb4ee759a5ae1234ee39": [
      {
        "path": "Ontology/TEIA-OntoEngine-Restore_e6b5626227b0.seed_cc74bc3922c4.seed_0c9eb3e4673d.seed (2).json",
        "size": 656
      },
      {
        "path": "Ontology/TEIA-OntoEngine-Restore_e6b5626227b0.seed_cc74bc3922c4.seed_0c9eb3e4673d.seed (1).json",
        "size": 656
      },
      {
        "path": "Ontology/TEIA-OntoEngine-Restore_e6b5626227b0.seed_cc74bc3922c4.seed_0c9eb3e4673d.seed (3).json",
        "size": 656
      }
    ],
    "29c7af7b8136917597909b91a9006264fd47cc569c5f743d54c8ba23e87744e5": [
      {
        "path": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed_614a77a8e5b5.seed_d295a489976e.seed (2).json",
        "size": 650
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed_614a77a8e5b5.seed_d295a489976e.seed.json",
        "size": 650
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed_614a77a8e5b5.seed_d295a489976e.seed (1).json",
        "size": 650
      },
      {
        "path": "Ontology/TEIA-OntoSeed-Gen_754c2e83b60d.seed_614a77a8e5b5.seed_d295a489976e.seed (3).json",
        "size": 650
      }
    ],
    "2607565b59369d5c5dfb896854b6c73a5e33862640482cdc851e8dae7a253f08": [
      {
        "path": "Ontology/TEIA-OntoEngine-Restore_e6b5626227b0.seed_42019f39afb7.seed (1).json",
        "size": 638
      },
      {
        "path": "Ontology/TEIA-OntoEngine-Restore_e6b5626227b0.seed_42019f39afb7.seed (3).json",
        "size": 638
      },
      {
        "path": "Ontology/TEIA-OntoEngine-Restore_e6b5626227b0.seed_42019f39afb7.seed (2).json",
        "size": 638
      }
    ],
    "8813abbb8f8036851c49e3939785884183589d54e3919f818e2ce02b5aa784b7": [
      {
        "path": "Ontology/teia_format_ontology_1500e7a56cbc.seed_57cff3d38f26.seed (1).json",
        "size": 635
      },
      {
        "path": "Ontology/teia_format_ontology_1500e7a56cbc.seed_57cff3d38f26.seed (2).json",
        "size": 635
      }
    ],
    "2257e055fa74bebf6441e1eba12b1ba4bbcd094708312ee1091a8dd0cc5b78a8": [
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoSeed-Gen.LowRAM_e68827162455.seed (2).json",
        "size": 176
      },
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoSeed-Gen.LowRAM_e68827162455.seed (1).json",
        "size": 176
      }
    ],
    "70007a2fa6fdd4bfc823a0eafcfc91cadca044289b2060176478f2c24d093a78": [
      {
        "path": "__MACOSX/Ontology/._teia_format_ontology_1500e7a56cbc.seed (3).json",
        "size": 176
      },
      {
        "path": "__MACOSX/Ontology/._teia_format_ontology_1500e7a56cbc.seed (2).json",
        "size": 176
      }
    ],
    "22dcbde51109ba534d7f8478db3fc2a5ab1c708ffd3d44ef37bfac61545312d7": [
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoSeed-Gen.LowRAM__dedup_E6882716 (3).ps1",
        "size": 176
      },
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoSeed-Gen.LowRAM__dedup_E6882716 (2).ps1",
        "size": 176
      }
    ],
    "ab8428c31e0b1baf0ba153b19d09262295be63ad65d85b12d5a4591203c57031": [
      {
        "path": "__MACOSX/Ontology/._teia_format_ontology_1500e7a56cbc.seed_57cff3d38f26.seed_c02101ba555b.seed (2).json",
        "size": 176
      },
      {
        "path": "__MACOSX/Ontology/._teia_format_ontology_1500e7a56cbc.seed_57cff3d38f26.seed_c02101ba555b.seed (1).json",
        "size": 176
      }
    ],
    "6e83586aa613ea65a68a61d4711806a288de84081132de87104ac06d5c1a87c4": [
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoEngine-Restore_e6b5626227b0.seed.json",
        "size": 176
      },
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoEngine-Restore_e6b5626227b0.seed (1).json",
        "size": 176
      }
    ],
    "a8bc776ac0b0d068e519940de431c1902002fe6ba9f2b0b7987646c060a3f5a7": [
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoSeed-Gen_754c2e83b60d.seed_614a77a8e5b5.seed.json",
        "size": 176
      },
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoSeed-Gen_754c2e83b60d.seed_6afba612ea1f.seed (3).json",
        "size": 176
      }
    ],
    "afce032105e70e0bdf250e101b128e29db8de336f9cde441b130e374e385e50b": [
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoSeed-Gen_754c2e83b60d.seed.json",
        "size": 176
      },
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoSeed-Gen__dedup_754C2E83 (3).ps1",
        "size": 176
      }
    ],
    "58c43c831f5434c1bacb21e5b0c0d1e96453d1b35acbcc39c2aa7a4e373b1e5f": [
      {
        "path": "__MACOSX/Ontology/._teia_format_ontology.json",
        "size": 176
      },
      {
        "path": "__MACOSX/Ontology/._ontology.py",
        "size": 176
      }
    ],
    "005b8f80e0f7a74b968d66735dabacd7c9c474a3b8775b871eb695b2725ffd2d": [
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoEngine-Restore_e6b5626227b0.seed_cc74bc3922c4.seed.json",
        "size": 176
      },
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoEngine-Restore_e6b5626227b0.seed_cc74bc3922c4.seed (1).json",
        "size": 176
      }
    ],
    "cdf1dfea1c132a0ead19c262a6beb5bd58abef0dbc2a7bc070f6e59d7ab4e3be": [
      {
        "path": "__MACOSX/Ontology/._teia_format_ontology_1500e7a56cbc.seed_57cff3d38f26.seed_c02101ba555b.seed (3).json",
        "size": 176
      },
      {
        "path": "__MACOSX/Ontology/._teia_format_ontology_f58a3fe56681.seed (1).json",
        "size": 176
      }
    ],
    "c3b4bd0492b8ee9063c172781b23648f402bbbf795e9cb209401c19dce808f21": [
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoSeed-Gen.LowRAM (1).ps1",
        "size": 176
      },
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoSeed-Gen.LowRAM.ps1",
        "size": 176
      }
    ],
    "3820d6cfbee0255fcab8f073dd367dc06e465e6ff79a940252ddb27bf529498c": [
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoSeed-Gen.LowRAM_e68827162455.seed_09932f925941.seed.json",
        "size": 176
      },
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoSeed-Gen.LowRAM_e68827162455.seed_09932f925941.seed (1).json",
        "size": 176
      }
    ],
    "ef571a3de14ebdf0abe4467b3844906cfefd9e73b486e2c09fce64c7bfc8c1c4": [
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoEngine-Restore (2).ps1",
        "size": 176
      },
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoEngine-Restore (1).ps1",
        "size": 176
      }
    ],
    "87d14276175b94ad80abf7836d0c9019cb4818b8083a150fdfa80adf80310da8": [
      {
        "path": "__MACOSX/Ontology/._teia_format_ontology_1b6d832c8c43.seed.json",
        "size": 176
      },
      {
        "path": "__MACOSX/Ontology/._teia_format_ontology_1b6d832c8c43.seed (2).json",
        "size": 176
      }
    ],
    "28c5b0129d966c8c136a9c31b9de976ac4212e73f82b10a294c22cb12c0867bb": [
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoSeed-Gen_754c2e83b60d.seed (3).json",
        "size": 176
      },
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoSeed-Gen_754c2e83b60d.seed_6afba612ea1f.seed.json",
        "size": 176
      }
    ],
    "3390305bb0bb3b88067484a66987bb567af5d9c53bd85142303821e0655060b5": [
      {
        "path": "__MACOSX/Ontology/._teia_format_ontology_f58a3fe56681.seed (3).json",
        "size": 176
      },
      {
        "path": "__MACOSX/Ontology/._teia_format_ontology_f58a3fe56681.seed (2).json",
        "size": 176
      }
    ],
    "fa24087234ba92784a0362c5b6e80015366c28c9a8acb99fabf4dbbeb22a5ef9": [
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoEngine-Restore_e6b5626227b0.seed (2).json",
        "size": 176
      },
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoEngine-Restore_e6b5626227b0.seed (3).json",
        "size": 176
      }
    ],
    "56ced7c9dfa06fcc9f12a7f9a3c831472d6c33cb8ace00060777d716271a69fe": [
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoSeed-Gen.ps1",
        "size": 176
      },
      {
        "path": "__MACOSX/Ontology/._TEIA-OntoSeed-Gen.LowRAM_e68827162455.seed_09932f925941.seed (3).json",
        "size": 176
      }
    ]
  }
}
'@

function Get-TEIAOntoSynth {
  return $synthJson | ConvertFrom-Json -Depth 10
}

function Write-TEIAOntoSynthJson {
  param([string]$Path = (Join-Path $OutDir 'teia_ontology_synth.json'))
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  Set-Content -LiteralPath $Path -Encoding UTF8 -Value $synthJson
  Write-Host "[OK] Wrote synth JSON => $Path"
}

function Show-TEIAOntoSummary {
  $s = Get-TEIAOntoSynth
  Write-Host ("Unique(non-mac)=0 | Total=1 | Duplicates(groups)=2 | Duplicates(files)=3" -f `
    $s.stats.unique_non_mac, $s.stats.total_files_in_zip, $s.stats.duplicates_groups, $s.stats.duplicates_files)
  Write-Host "Ext dist (unique_non_mac):"
  $s.stats.ext_distribution_unique_non_mac.GetEnumerator() | Sort-Object Name | Format-Table -AutoSize | Out-String -Width 200 | Write-Output
  Write-Host "Scripts digest:"
  $s.scripts_digest | Format-Table path, size, sha256 -AutoSize | Out-String -Width 200 | Write-Output
  $seedCount = ($s.seeds | Measure-Object).Count
  Write-Host "Seeds indexed: $seedCount"
}

if ($WriteJson) { Write-TEIAOntoSynthJson }
if ($PrintSummary) { Show-TEIAOntoSummary }
