import {batchTransfer, buyMMM314, pledgeCount} from "./Hepler";
import 'dotenv/config'
const mmm314 = process.env.MMM314 || "";
const mmm314pledge = process.env.MMM314Pledge || "";
async function main() {
    // await batchTransfer();
    // await buyMMM314(mmm314,mmm314pledge);
    await pledgeCount(mmm314pledge);
}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});