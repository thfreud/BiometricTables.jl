using BiometricTables
using Documenter

DocMeta.setdocmeta!(BiometricTables, :DocTestSetup, :(using BiometricTables); recursive=true)

makedocs(;
    modules=[BiometricTables],
    authors="thfreud <thfreud@gmail.com> and contributors",
    repo = "https://github.com/thfreud/BiometricTables.jl/blob/{commit}{path}#{line}",
    sitename="BiometricTables.jl",
    format=Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical="https://thfreud.github.io/BiometricTables.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/thfreud/BiometricTables.jl",
    devbranch="main",
)
