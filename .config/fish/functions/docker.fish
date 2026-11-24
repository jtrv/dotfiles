# sudo drops exported env vars, and plain `docker build` ignores `buildx use`;
# only BUILDX_BUILDER on the sudo line routes builds to the gVisor builder.
function docker --wraps docker --description 'rootful docker; builds use the gvisor buildx builder'
    if command -q runsc
        sudo BUILDX_BUILDER=gvisor docker $argv
    else
        command docker $argv
    end
end
