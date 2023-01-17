using Polylabel
using Documenter

DocMeta.setdocmeta!(Polylabel, :DocTestSetup, :(using Polylabel); recursive=true)

makedocs(;
    modules=[Polylabel],
    authors="Anshul Singhvi <anshulsinghvi@gmail.com> and contributors",
    repo="https://github.com/asinghvi17/Polylabel.jl/blob/{commit}{path}#{line}",
    sitename="Polylabel.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://asinghvi17.github.io/Polylabel.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/asinghvi17/Polylabel.jl",
    devbranch="main",
)
