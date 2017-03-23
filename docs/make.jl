using Documenter, LaxZonedDateTimes

makedocs(
    modules = [LaxZonedDateTimes],
    format = :html,
    pages = [],
    repo = "https://gitlab.invenia.ca/invenia/LaxZonedDateTimes.jl/blob/{commit}{path}#L{line}",
    sitename = "LaxZonedDateTimes.jl",
    authors = "Curtis Vogt, Gem Newman",
    assets = ["assets/invenia.css"],
)

