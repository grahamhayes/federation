load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["main.go"],
    importpath = "github.com/mailru/easyjson/easyjson",
    visibility = ["//visibility:private"],
    deps = [
        "//vendor/github.com/mailru/easyjson/bootstrap:go_default_library",
        "//vendor/github.com/mailru/easyjson/gen:go_default_library",
        "//vendor/github.com/mailru/easyjson/parser:go_default_library",
    ],
)

go_binary(
    name = "easyjson",
    importpath = "github.com/mailru/easyjson/easyjson",
    library = ":go_default_library",
    visibility = ["//visibility:public"],
)

filegroup(
    name = "package-srcs",
    srcs = glob(["**"]),
    tags = ["automanaged"],
    visibility = ["//visibility:private"],
)

filegroup(
    name = "all-srcs",
    srcs = [":package-srcs"],
    tags = ["automanaged"],
    visibility = ["//visibility:public"],
)
