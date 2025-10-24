#let t = sys.inputs.at("t", default: 300)

#rect(
    height: 100%,
    width: 100%,
    fill: rgb("f0f0f0"),
    align(
        center + horizon,
        text(16pt, "Frame: " + str(t))
    )
)
