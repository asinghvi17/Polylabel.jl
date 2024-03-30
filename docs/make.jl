using Polylabel
using Documenter, DocumenterVitepress

DocMeta.setdocmeta!(Polylabel, :DocTestSetup, :(using Polylabel); recursive=true)

makedocs(;
    modules=[Polylabel],
    authors="Anshul Singhvi <anshulsinghvi@gmail.com> and contributors",
    repo="https://github.com/asinghvi17/Polylabel.jl/blob/{commit}{path}#{line}",
    sitename="Polylabel.jl",
    format=DocumenterVitepress.MarkdownVitepress(;
        repo = "https://github.com/asinghvi17/Polylabel.jl",
        devurl = "dev",
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/asinghvi17/Polylabel.jl",
    devbranch="main",
    push_preview = true,
)
