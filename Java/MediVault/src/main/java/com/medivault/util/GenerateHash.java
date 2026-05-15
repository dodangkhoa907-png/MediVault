package com.medivault.util;

public class GenerateHash {
    public static void main(String[] args) {
        String hash = PasswordUtil.hashPassword("123456");
        System.out.println("Length: " + hash.length()); // phải là 60
        System.out.println("Hash: [" + hash + "]");     // dấu [] để thấy rõ đầu cuối
    }
}