using BiometricTables
using Documenter

DocMeta.setdocmeta!(BiometricTables, :DocTestSetup, :(using BiometricTables); recursive=true)

makedocs(;
    modules=[BiometricTables],
    authors="thfreud <thfreud@gmail.com> and contributors",
    sitename="BiometricTables.jl",
    format=Documenter.HTML(;
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
