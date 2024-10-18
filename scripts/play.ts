import {batchTransfer, buyMMM314, getMMM314Price, pledgeCount} from "./Hepler";
import 'dotenv/config'
const mmm314 = process.env.MMM314 || "";
const mmm314pledge = process.env.MMM314Pledge || "";
async function main() {
    const price = await getMMM314Price(mmm314);
    console.log(Number(price) * 580)
}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});