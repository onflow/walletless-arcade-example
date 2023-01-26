async function purchaseNft() {
  await fetch('/api/stripe', { method: 'POST' }).then(async response => {
    if (response.ok) {
      const { url }: any = await response.json()
      window.location.href = url
    }
  })
}

export default purchaseNft
