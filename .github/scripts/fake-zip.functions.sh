create_fake_distribution_zip() {
    local output_zip="$1"
    if [[ -z "${output_zip}" ]]; then
        echo "Usage: create_fake_distribution_zip <output_zip_path>" >&2
        return 1
    fi

    local dist_dir
    dist_dir=$(mktemp -d)
    mkdir -p "${dist_dir}/hazelcast-0.0.0/bin" "${dist_dir}/hazelcast-0.0.0/lib"
    printf '#!/bin/bash\n' > "${dist_dir}/hazelcast-0.0.0/bin/hz"
    printf '#!/bin/bash\n' > "${dist_dir}/hazelcast-0.0.0/bin/hz-healthcheck"
    chmod +x "${dist_dir}/hazelcast-0.0.0/bin/"*
    touch "${dist_dir}/hazelcast-0.0.0/lib/placeholder"
    (cd "${dist_dir}" && zip -qr "${output_zip}" hazelcast-0.0.0/)
    rm -rf "${dist_dir}"
}
